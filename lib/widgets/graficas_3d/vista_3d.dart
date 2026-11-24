import 'package:flutter/material.dart';

import '../../models/datos_graficas.dart';
import 'capsulas_3d.dart';
import 'comunes_3d.dart';
import 'dona_3d.dart';
import 'radar_3d.dart';

enum _Grafica3D { capsulas, radar, dona }

/// Datos ya cargados + mapa de color por categoría, tal como los usa la
/// vista clásica.
typedef ConColores<T> = (T, Map<String, Color>);

/// Vista 3D del módulo de gráficas: selector en línea de 3 gráficas y la
/// gráfica elegida dentro de una tarjeta.
///
/// Recibe los MISMOS Future que usan las gráficas clásicas ("Ventas por mes"
/// y "Ventas por categoría"): mismas listas en memoria y mismo mapa de colores,
/// sin consultas nuevas ni datos recalculados.
class Vista3D extends StatefulWidget {
  const Vista3D({super.key, required this.porMes, required this.porCategoria});

  final Future<ConColores<List<SerieVentas>>> porMes;
  final Future<ConColores<List<VentaCategoria>>> porCategoria;

  @override
  State<Vista3D> createState() => _Vista3DState();
}

class _Vista3DState extends State<Vista3D> {
  _Grafica3D _grafica = _Grafica3D.capsulas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_Grafica3D>(
          style: estiloSegmentos3D(context),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Grafica3D.capsulas, label: Text('Cápsulas')),
            ButtonSegment(value: _Grafica3D.radar, label: Text('Radar')),
            ButtonSegment(value: _Grafica3D.dona, label: Text('Dona')),
          ],
          selected: {_grafica},
          onSelectionChanged: (s) => setState(() => _grafica = s.first),
        ),
        const SizedBox(height: 18),
        Tarjeta3D(
          // La clave reinicia la gráfica (y su animación de entrada) al cambiar.
          child: KeyedSubtree(
            key: ValueKey(_grafica),
            child: switch (_grafica) {
              _Grafica3D.capsulas => _conDatos(
                widget.porCategoria,
                (d, colores) =>
                    d.isEmpty ? null : Capsulas3D(datos: d, colores: colores),
              ),
              _Grafica3D.radar => _conDatos(
                widget.porMes,
                (d, colores) =>
                    d.isEmpty ? null : Radar3D(series: d, colores: colores),
              ),
              _Grafica3D.dona => _conDatos(
                widget.porCategoria,
                (d, colores) =>
                    d.isEmpty ? null : Dona3D(datos: d, colores: colores),
              ),
            },
          ),
        ),
      ],
    );
  }

  /// Cargando / error / sin datos / gráfica (null = sin datos).
  Widget _conDatos<T>(
    Future<ConColores<T>> futuro,
    Widget? Function(T datos, Map<String, Color> colores) construir,
  ) {
    return FutureBuilder<ConColores<T>>(
      future: futuro,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Estado3D.cargando();
        }
        if (snap.hasError || snap.data == null) return const Estado3D.error();
        final (datos, colores) = snap.data!;
        return construir(datos, colores) ?? const Estado3D.vacio();
      },
    );
  }
}
