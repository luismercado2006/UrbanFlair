import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/datos_graficas.dart';
import '../../theme/app_colors.dart';
import 'comunes_3d.dart';
import 'motor_3d.dart';
import 'visor_3d.dart';

/// Radar poligonal con los mismos datos de "Ventas por mes" de la vista
/// clásica: cada eje es una categoría y cada mes es una capa apilada en
/// profundidad (eje Z), del más antiguo (atrás, más claro) al más reciente
/// (adelante, más oscuro).
/// - Los meses sin ventas siguen en los datos, pero no se dibujan como capa.
/// - Por defecto se ven los 3 meses más recientes con ventas.
class Radar3D extends StatefulWidget {
  const Radar3D({super.key, required this.series, required this.colores});

  final List<SerieVentas> series;
  final Map<String, Color> colores;

  @override
  State<Radar3D> createState() => _Radar3DState();
}

/// Ids de lo que se puede tocar.
typedef _Vertice = ({int mes, int categoria});
typedef _Capa = ({int mes});

class _Radar3DState extends State<Radar3D> {
  static const _radio = 1.0;
  static const _profundidad = 1.1;
  static const _anillos = 4;
  static const _mesesIniciales = 3;

  late final List<SerieVentas> _series;
  late final List<String> _meses;
  late final List<int> _mesesConVentas;
  late final Set<int> _mesesVisibles;
  final _categoriasOcultas = <String>{};
  Object? _seleccion;

  @override
  void initState() {
    super.initState();
    // Ejes en orden alfabético; los valores son los mismos de la vista clásica.
    _series = [
      ...widget.series,
    ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    _meses = _series.isEmpty
        ? const []
        : [for (final p in _series.first.puntos) p.mes];
    _mesesConVentas = [
      for (var m = 0; m < _meses.length; m++)
        if (_totalMes(m) > 0) m,
    ];
    final n = _mesesConVentas.length;
    _mesesVisibles = {
      ..._mesesConVentas.sublist(math.max(0, n - _mesesIniciales)),
    };
  }

  double _valor(int c, int m) =>
      m < _series[c].puntos.length ? _series[c].puntos[m].unidades : 0;

  double _totalMes(int m) {
    var s = 0.0;
    for (var c = 0; c < _series.length; c++) {
      s += _valor(c, m);
    }
    return s;
  }

  Color _colorCategoria(int c) =>
      Colores3D.deCategoria(widget.colores, _series[c].nombre);

  @override
  Widget build(BuildContext context) {
    if (_meses.isEmpty) return const Estado3D.vacio();

    final total = [for (var m = 0; m < _meses.length; m++) _totalMes(m)]
        .fold<double>(0, (a, b) => a + b);

    final tema = Theme.of(context).textTheme;
    final estiloEje = (tema.labelSmall ?? const TextStyle()).copyWith(
      color: AppColors.azulTitulo,
      fontWeight: FontWeight.w600,
      fontSize: 10,
    );

    final (String?, List<(String, String)>) panel = switch (_seleccion) {
      (mes: final int m, categoria: final int c) => (
        _series[c].nombre,
        [
          ('Mes', _meses[m]),
          ('Unidades', unidades(_valor(c, m))),
          ('Del mes', porcentaje(_valor(c, m), _totalMes(m))),
        ],
      ),
      (mes: final int m) => (
        'Mes: ${_meses[m]}',
        [
          ('Unidades', unidades(_totalMes(m))),
          ('Del total', porcentaje(_totalMes(m), total)),
        ],
      ),
      _ => (null, const <(String, String)>[]),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Titulo3D('Ventas por mes'),
        Visor3D(
          // Alto según el ancho; escala pensada para dejar sitio a etiquetas.
          escalaBase: 0.31,
          yawInicial: -0.45,
          pitchInicial: 0.3,
          zoomMax: 2,
          distancia: 5,
          alTocar: (id) => setState(() => _seleccion = id),
          construir: (entrada) => _escena(entrada, estiloEje),
        ),
        const SizedBox(height: 8),
        Leyenda3D(
          titulo: 'Categorías',
          ayuda: 'Toca una categoría para ocultar o mostrar su eje',
          elementos: [
            for (var c = 0; c < _series.length; c++)
              ElementoLeyenda(
                _series[c].nombre,
                _colorCategoria(c),
                activo: !_categoriasOcultas.contains(_series[c].nombre),
              ),
          ],
          alTocar: (c) => setState(() {
            final nombre = _series[c].nombre;
            if (!_categoriasOcultas.remove(nombre)) {
              _categoriasOcultas.add(nombre);
            }
            final sel = _seleccion;
            if (sel is _Vertice && sel.categoria == c) _seleccion = null;
          }),
        ),
        const SizedBox(height: 8),
        Leyenda3D(
          titulo: 'Meses (capas)',
          ayuda:
              'Toca un mes para mostrarlo u ocultarlo · '
              'los meses sin ventas no se dibujan',
          elementos: [
            for (var m = 0; m < _meses.length; m++)
              ElementoLeyenda(
                _meses[m],
                Colores3D.capa(m, _meses.length),
                activo: _mesesVisibles.contains(m),
                habilitado: _mesesConVentas.contains(m),
              ),
          ],
          alTocar: (m) => setState(() {
            if (!_mesesVisibles.remove(m)) _mesesVisibles.add(m);
            final sel = _seleccion;
            if ((sel is _Vertice && sel.mes == m) ||
                (sel is _Capa && sel.mes == m)) {
              _seleccion = null;
            }
          }),
        ),
        const SizedBox(height: 10),
        Panel3D(titulo: panel.$1, filas: panel.$2),
      ],
    );
  }

  List<Primitiva3D> _escena(double entrada, TextStyle estiloEje) {
    final out = <Primitiva3D>[];
    final ejes = [
      for (var c = 0; c < _series.length; c++)
        if (!_categoriasOcultas.contains(_series[c].nombre)) c,
    ];
    final k = ejes.length;
    if (k == 0) return out;

    // Solo meses con ventas, en orden cronológico.
    final capas = [
      for (final m in _mesesConVentas)
        if (_mesesVisibles.contains(m)) m,
    ];
    final nv = capas.length;

    var maximo = 0.0;
    for (final c in ejes) {
      for (final m in capas) {
        maximo = math.max(maximo, _valor(c, m));
      }
    }
    if (maximo <= 0) maximo = 1;

    // Las capas se separan en Z mientras la gráfica se despliega.
    final atras = -_profundidad / 2 * entrada;
    final frente = -atras;
    double zDe(int j) =>
        nv <= 1 ? 0 : atras + j * (_profundidad * entrada) / (nv - 1);

    double angulo(int j) => math.pi / 2 - 2 * math.pi * j / k;
    Vec3 punto(int j, double r, double z) =>
        Vec3(r * math.cos(angulo(j)), r * math.sin(angulo(j)), z);

    // Red de anillos poligonales y ejes, en el plano del fondo.
    final zFondo = atras - 0.02;
    const red = AppColors.tarjetaGris;
    final radioRed = _radio * entrada;
    for (var a = 1; a <= _anillos; a++) {
      final r = radioRed * a / _anillos;
      for (var j = 0; j < k; j++) {
        out.add(
          Linea3D(
            punto(j, r, zFondo),
            punto((j + 1) % k, r, zFondo),
            red,
            ancho: a == _anillos ? 1.4 : 0.9,
            sesgo: -10,
          ),
        );
      }
    }
    for (var j = 0; j < k; j++) {
      out.add(
        Linea3D(
          Vec3(0, 0, zFondo),
          punto(j, radioRed, zFondo),
          red,
          sesgo: -10,
        ),
      );
      // Nombre del eje, hacia afuera del radar y con el punto de su color.
      out.add(
        Texto3D(
          punto(j, radioRed * 1.06, frente),
          _series[ejes[j]].nombre,
          estiloEje,
          punto: _colorCategoria(ejes[j]),
          alejarDe: Vec3(0, 0, frente),
          anchoMax: 90,
        ),
      );
    }
    // Columna central que une las capas en profundidad.
    out.add(
      Linea3D(
        Vec3(0, 0, zFondo),
        Vec3(0, 0, frente),
        AppColors.textoGris.withValues(alpha: 0.6),
        ancho: 1.2,
      ),
    );

    // Capas: un polígono por mes con ventas, con un punto en cada vértice.
    for (var j = 0; j < nv; j++) {
      final m = capas[j];
      final z = zDe(j);
      final avance = ((entrada - 0.4 * j / math.max(1, nv - 1)) / 0.6).clamp(
        0.0,
        1.0,
      );
      final color = Colores3D.capa(m, _meses.length);
      final sel = _seleccion;
      final capaElegida = sel is _Capa && sel.mes == m;

      final vertices = [
        for (var j2 = 0; j2 < k; j2++)
          punto(j2, _radio * _valor(ejes[j2], m) / maximo * avance, z),
      ];
      out.add(
        Cara3D(
          vertices,
          color.withValues(alpha: capaElegida ? 0.45 : 0.26),
          sombrear: false,
          borde: capaElegida ? Colores3D.resaltado : color,
          anchoBorde: capaElegida ? 2.6 : 1.5,
          id: (mes: m),
        ),
      );
      for (var j2 = 0; j2 < k; j2++) {
        final c = ejes[j2];
        final elegido = sel is _Vertice && sel.mes == m && sel.categoria == c;
        out.add(
          Punto3D(
            vertices[j2],
            elegido ? 6 : 3.2,
            color,
            borde: elegido ? Colores3D.resaltado : Colors.white,
            anchoBorde: elegido ? 3 : 1.4,
            id: (mes: m, categoria: c),
            sesgo: 0.01,
          ),
        );
      }
    }
    return out;
  }
}
