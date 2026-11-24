import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/datos_graficas.dart';
import '../../theme/app_colors.dart';
import 'comunes_3d.dart';
import 'motor_3d.dart';
import 'visor_3d.dart';

/// Una cápsula 3D por categoría, ordenadas de mayor a menor, con los mismos
/// datos de "Ventas por categoría" de la vista clásica.
/// - El número muestra el % real de unidades sobre el total.
/// - El relleno (color de la categoría) se escala contra la categoría visible
///   con más unidades (esa queda llena al 100 %).
/// Cada cápsula gira en su propio sitio, así ninguna se sale de la tarjeta.
class Capsulas3D extends StatefulWidget {
  const Capsulas3D({super.key, required this.datos, required this.colores});

  final List<VentaCategoria> datos;
  final Map<String, Color> colores;

  @override
  State<Capsulas3D> createState() => _Capsulas3DState();
}

class _Capsulas3DState extends State<Capsulas3D> {
  static const _escalaBase = 0.36;

  // Medidas en unidades de la escena (centradas en cada cápsula).
  static const _radio = 0.2;
  static const _altoCapsula = 1.6;
  static const _altoTapa = 0.08;
  static const _lados = 12;
  static const _tramos = 4; // cortes verticales del cuerpo (mejor orden)
  static const _base = -0.78; // y de la base

  final _ocultas = <String>{};
  String? _seleccion;

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
    // Ordenadas de mayor a menor: la primera visible es la de más unidades.
    final mayor = visibles.isEmpty ? 0.0 : visibles.first.unidades;

    final tema = Theme.of(context).textTheme;
    final estiloNumero = (tema.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.azulTitulo,
      fontWeight: FontWeight.w900,
      fontSize: 15,
    );
    final estiloNombre = (tema.labelSmall ?? const TextStyle()).copyWith(
      color: AppColors.azulTitulo,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Titulo3D('Ventas por categoría (% del total)'),
        LayoutBuilder(
          builder: (context, c) {
            // Aprovecha el espacio: más alto en pantallas anchas y, si caben,
            // las cápsulas se reparten a lo ancho de la tarjeta.
            final alto = (c.maxWidth * 0.6).clamp(340.0, 480.0);
            final n = math.max(1, visibles.length);
            final hueco = math.max(0.26 * alto, c.maxWidth / n);
            return Visor3D(
              alto: alto,
              escalaPorAlto: true,
              escalaBase: _escalaBase,
              anchoContenido: visibles.length * hueco,
              yawInicial: -0.25,
              pitchInicial: 0.3,
              // Límites de giro y zoom: ninguna cápsula se corta en el borde
              // ni se montan los porcentajes.
              pitchMin: 0,
              pitchMax: 0.55,
              rangoYaw: (-0.6, 0.6),
              zoomMin: 0.8,
              zoomMax: 1.3,
              // Cámara lejana: casi sin deformación de perspectiva.
              distancia: 30,
              // Arrastre horizontal = recorrer la fila; vertical = rotar.
              arrastreHorizontalDesplaza: true,
              alTocar: (id) => setState(() => _seleccion = id as String?),
              construir: (entrada) => _escena(
                visibles,
                total,
                mayor,
                hueco,
                entrada,
                estiloNumero,
                estiloNombre,
              ),
            );
          },
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
                  (
                    'Relleno (vs. la mayor)',
                    porcentaje(elegida.unidades, mayor),
                  ),
                ],
        ),
      ],
    );
  }

  List<Primitiva3D> _escena(
    List<VentaCategoria> visibles,
    double total,
    double mayor,
    double hueco,
    double entrada,
    TextStyle estiloNumero,
    TextStyle estiloNombre,
  ) {
    final out = <Primitiva3D>[];
    final n = visibles.length;

    for (var i = 0; i < n; i++) {
      final d = visibles[i];
      // Lugar de la cápsula en pantalla (cada una gira en su sitio).
      final px = (i - (n - 1) / 2) * hueco;
      // Relleno relativo a la mayor (0 a 1); el número usa el total.
      final relleno = mayor <= 0 ? 0.0 : d.unidades / mayor;
      final elegida = d.categoria == _seleccion;
      // Llenado escalonado: cada cápsula empieza un poco después.
      final avance = ((entrada - i * 0.03) / 0.7).clamp(0.0, 1.0);

      const y0 = _base;
      const yTop = _base + _altoCapsula;
      const interiorDesde = y0 + _altoTapa;
      const interiorHasta = yTop - _altoTapa;
      final llenoHasta =
          interiorDesde + (interiorHasta - interiorDesde) * relleno * avance;

      // Color de la categoría (igual que en la vista clásica). Al tocarla se
      // resalta con brillo y con tapas y vidrio celestes, sin cambiar su color.
      final colorCategoria = Colores3D.deCategoria(widget.colores, d.categoria);
      final colorRelleno = elegida
          ? Colores3D.tono(colorCategoria, 0.12)
          : colorCategoria;
      final colorTapa = elegida ? Colores3D.resaltado : AppColors.azulTitulo;

      void prisma(double ya, double yb, double r, Color color, double sesgo) =>
          _prisma(out, ya, yb, r, color, id: d.categoria, px: px, sesgo: sesgo);

      // Tapas (sólidas). La de abajo se pinta primero (el relleno se apoya en\n      // ella) y la de arriba al final (nada de la cápsula la tapa).
      prisma(y0, interiorDesde, _radio * 1.12, colorTapa, -0.3);
      prisma(interiorHasta, yTop, _radio * 1.12, colorTapa, 0.3);

      // Relleno interior (la mayor llega hasta arriba). Se corta en los mismos
      // tramos que el vidrio y va un poco adelante en el orden de pintado,
      // para que se vea con el color exacto de la categoría, parejo.
      const altoTramo = (interiorHasta - interiorDesde) / _tramos;
      for (var t = 0; t < _tramos; t++) {
        final ya = interiorDesde + t * altoTramo;
        final yb = math.min(ya + altoTramo, llenoHasta);
        if (yb - ya <= 0.002) break;
        _prisma(
          out,
          ya,
          yb,
          _radio * 0.8,
          colorRelleno,
          id: d.categoria,
          px: px,
          conTapas: yb >= llenoHasta, // solo la tapa del último tramo
          sesgo: 0.2,
        );
      }

      // Cuerpo translúcido (se ven sus dos lados, como vidrio).
      final vidrio = (elegida ? Colores3D.resaltado : AppColors.tarjetaGris)
          .withValues(alpha: elegida ? 0.28 : 0.38);
      for (var t = 0; t < _tramos; t++) {
        final ya = interiorDesde + t * altoTramo, yb = ya + altoTramo;
        for (var k = 0; k < _lados; k++) {
          final a0 = 2 * math.pi * k / _lados,
              a1 = 2 * math.pi * (k + 1) / _lados;
          out.add(
            Cara3D(
              [
                _anillo(ya, _radio, a0),
                _anillo(ya, _radio, a1),
                _anillo(yb, _radio, a1),
                _anillo(yb, _radio, a0),
              ],
              vidrio,
              id: d.categoria,
              desplazPx: px,
            ),
          );
        }
      }

      // Número grande (% real del total) sobre la parte inferior y nombre
      // debajo, limitado al ancho de su hueco para que no se monten.
      out.add(
        Texto3D(
          const Vec3(0, interiorDesde + 0.42, _radio * 1.2),
          porcentaje(d.unidades * avance, total),
          estiloNumero,
          fondo: Colors.white.withValues(alpha: 0.85),
          anchoMax: hueco - 8,
          desplazPx: px,
        ),
      );
      out.add(
        Texto3D(
          const Vec3(0, y0 - 0.2, 0),
          d.categoria,
          estiloNombre,
          anchoMax: hueco - 8,
          desplazPx: px,
        ),
      );
    }
    return out;
  }

  static Vec3 _anillo(double y, double r, double a) =>
      Vec3(r * math.cos(a), y, r * math.sin(a));

  /// Prisma cerrado (cilindro facetado) con caras laterales, tapa y base.
  void _prisma(
    List<Primitiva3D> out,
    double y0,
    double y1,
    double r,
    Color color, {
    required Object id,
    required double px,
    bool conTapas = true,
    double sesgo = 0,
  }) {
    final centro = Vec3(0, (y0 + y1) / 2, 0);
    for (var k = 0; k < _lados; k++) {
      final a0 = 2 * math.pi * k / _lados, a1 = 2 * math.pi * (k + 1) / _lados;
      out.add(
        Cara3D(
          [
            _anillo(y0, r, a0),
            _anillo(y0, r, a1),
            _anillo(y1, r, a1),
            _anillo(y1, r, a0),
          ],
          color,
          centroSolido: centro,
          id: id,
          sesgo: sesgo,
          desplazPx: px,
        ),
      );
    }
    if (!conTapas) return;
    for (final y in [y1, y0]) {
      out.add(
        Cara3D(
          [
            for (var k = 0; k < _lados; k++)
              _anillo(y, r, 2 * math.pi * k / _lados),
          ],
          color,
          centroSolido: centro,
          id: id,
          sesgo: sesgo,
          desplazPx: px,
        ),
      );
    }
  }
}
