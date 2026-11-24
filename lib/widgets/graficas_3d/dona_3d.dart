import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/datos_graficas.dart';
import '../../theme/app_colors.dart';
import 'comunes_3d.dart';
import 'motor_3d.dart';
import 'visor_3d.dart';

/// Dona extruida: participación de cada categoría en el total, con los mismos
/// datos y colores de "Ventas por categoría" de la vista clásica.
/// Al tocar una porción, se separa, se eleva y se ilumina (mismo color).
class Dona3D extends StatefulWidget {
  const Dona3D({super.key, required this.datos, required this.colores});

  final List<VentaCategoria> datos;
  final Map<String, Color> colores;

  @override
  State<Dona3D> createState() => _Dona3DState();
}

class _Dona3DState extends State<Dona3D> with SingleTickerProviderStateMixin {
  static const _radioInterior = 0.5;
  static const _radioExterior = 1.0;
  static const _grosor = 0.3;
  static const _pasoAngulo = math.pi / 30; // 6° por segmento
  static const _separacionMax = 0.14;
  static const _elevacionMax = 0.06;

  late final AnimationController _separacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  final _ocultas = <String>{};
  String? _seleccion;

  @override
  void dispose() {
    _separacion.dispose();
    super.dispose();
  }

  void _tocar(Object? id) {
    setState(() => _seleccion = id as String?);
    _separacion.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.datos.fold<double>(0, (s, d) => s + d.unidades);
    final ordenadas = [...widget.datos]
      ..sort((a, b) => b.unidades.compareTo(a.unidades));
    final visibles = ordenadas
        .where((d) => !_ocultas.contains(d.categoria))
        .toList();
    final elegida = visibles
        .where((d) => d.categoria == _seleccion)
        .firstOrNull;

    final tema = Theme.of(context).textTheme;
    final estiloPct = (tema.labelSmall ?? const TextStyle()).copyWith(
      color: AppColors.azulTitulo,
      fontWeight: FontWeight.w800,
      fontSize: 10,
    );
    final estiloTotal = (tema.titleSmall ?? const TextStyle()).copyWith(
      color: AppColors.azulTitulo,
      fontWeight: FontWeight.w900,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Titulo3D('Participación por categoría'),
        Visor3D(
          // Alto según el ancho y escala grande: la dona ocupa casi todo.
          escalaBase: 0.42,
          yawInicial: 0,
          pitchInicial: 0.75,
          pitchMin: 0.1,
          pitchMax: 1.5,
          zoomMax: 2,
          distancia: 5,
          repintar: _separacion,
          alTocar: _tocar,
          construir: (entrada) =>
              _escena(visibles, total, entrada, estiloPct, estiloTotal),
        ),
        const SizedBox(height: 8),
        Leyenda3D(
          ayuda: 'Toca una categoría para ocultarla o mostrarla',
          elementos: [
            for (final d in ordenadas)
              ElementoLeyenda(
                d.categoria,
                Colores3D.deCategoria(widget.colores, d.categoria),
                activo: !_ocultas.contains(d.categoria),
              ),
          ],
          alTocar: (i) => setState(() {
            final c = ordenadas[i].categoria;
            if (!_ocultas.remove(c)) _ocultas.add(c);
            if (_seleccion == c) _seleccion = null;
          }),
        ),
        const SizedBox(height: 10),
        Panel3D(
          titulo: elegida?.categoria,
          filas: elegida == null
              ? const []
              : [
                  ('Unidades', unidades(elegida.unidades)),
                  ('Del total', porcentaje(elegida.unidades, total)),
                ],
        ),
      ],
    );
  }

  List<Primitiva3D> _escena(
    List<VentaCategoria> visibles,
    double total,
    double entrada,
    TextStyle estiloPct,
    TextStyle estiloTotal,
  ) {
    final out = <Primitiva3D>[];
    final totalVisible = visibles.fold<double>(0, (s, d) => s + d.unidades);
    if (totalVisible <= 0) return out;

    // La dona se arma: el giro total crece y las porciones ganan altura.
    final barrido = 2 * math.pi * entrada;
    final alto = _grosor * (0.25 + 0.75 * entrada);
    final rMedio = (_radioInterior + _radioExterior) / 2;
    final avanceSel = Curves.easeOut.transform(_separacion.value);

    var inicio = -math.pi / 2;
    for (final d in visibles) {
      final ang = d.unidades / totalVisible * barrido;
      if (ang <= 0) continue;
      final fin = inicio + ang;
      final elegida = d.categoria == _seleccion;
      final colorCategoria = Colores3D.deCategoria(widget.colores, d.categoria);
      // Resaltado: más brillo, sin cambiar el color de la categoría.
      final color = elegida
          ? Colores3D.tono(colorCategoria, 0.12)
          : colorCategoria;
      final medio = (inicio + fin) / 2;
      final desplazar = elegida
          ? Vec3(
              math.cos(medio) * _separacionMax * avanceSel,
              _elevacionMax * avanceSel,
              math.sin(medio) * _separacionMax * avanceSel,
            )
          : const Vec3(0, 0, 0);
      final y0 = -alto / 2, y1 = alto / 2;

      Vec3 p(double a, double r, double y) =>
          Vec3(r * math.cos(a), y, r * math.sin(a)) + desplazar;

      final segmentos = math.max(1, (ang / _pasoAngulo).ceil());
      for (var s = 0; s < segmentos; s++) {
        final b0 = inicio + ang * s / segmentos;
        final b1 = inicio + ang * (s + 1) / segmentos;
        final centro = p((b0 + b1) / 2, rMedio, 0);
        void cara(List<Vec3> pts) =>
            out.add(Cara3D(pts, color, centroSolido: centro, id: d.categoria));

        // Arriba, abajo, borde exterior y borde interior del segmento.
        cara([
          p(b0, _radioInterior, y1),
          p(b0, _radioExterior, y1),
          p(b1, _radioExterior, y1),
          p(b1, _radioInterior, y1),
        ]);
        cara([
          p(b0, _radioInterior, y0),
          p(b0, _radioExterior, y0),
          p(b1, _radioExterior, y0),
          p(b1, _radioInterior, y0),
        ]);
        cara([
          p(b0, _radioExterior, y0),
          p(b1, _radioExterior, y0),
          p(b1, _radioExterior, y1),
          p(b0, _radioExterior, y1),
        ]);
        cara([
          p(b0, _radioInterior, y0),
          p(b1, _radioInterior, y0),
          p(b1, _radioInterior, y1),
          p(b0, _radioInterior, y1),
        ]);
        // Tapas de los extremos de la porción.
        List<Vec3> tapa(double a) => [
          p(a, _radioInterior, y0),
          p(a, _radioExterior, y0),
          p(a, _radioExterior, y1),
          p(a, _radioInterior, y1),
        ];
        if (s == 0) cara(tapa(b0));
        if (s == segmentos - 1) cara(tapa(b1));
      }

      // Porcentaje sobre la porción (si cabe).
      if (entrada > 0.95 && d.unidades / totalVisible >= 0.04) {
        out.add(
          Texto3D(
            p(medio, rMedio, y1 + 0.01),
            porcentaje(d.unidades, total),
            estiloPct,
            fondo: Colors.white.withValues(alpha: 0.8),
          ),
        );
      }
      inicio = fin;
    }

    // Total al centro (el mismo total de "Ventas por categoría").
    out.add(
      Texto3D(
        const Vec3(0, 0, 0),
        '${unidades((total * entrada).roundToDouble())}\nunidades',
        estiloTotal,
        sesgo: 0,
      ),
    );
    return out;
  }
}
