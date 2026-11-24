import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../data/ventas_repositorio.dart';
import '../models/datos_graficas.dart';
import '../theme/app_colors.dart';
import '../theme/colores_graficas.dart';
import '../widgets/encabezado_azul.dart';
import '../widgets/graficas_3d/comunes_3d.dart';
import '../widgets/graficas_3d/vista_3d.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final _repo = VentasRepositorio();
  late final Future<List<SerieVentas>> _porMes = _repo.ventasPorMes();
  late final Future<List<VentaCategoria>> _porCategoria =
      _repo.ventasPorCategoria();

  /// Color fijo por categoría (mismo en la vista clásica y en la 3D): se juntan
  /// las categorías de ambas consultas y se colorean con ColoresGraficas.
  late final Future<Map<String, Color>> _colores = _calcularColores();

  late final Future<(List<SerieVentas>, Map<String, Color>)> _mesConColores =
      _porMes.then((d) async => (d, await _colores));
  late final Future<(List<VentaCategoria>, Map<String, Color>)>
      _categoriaConColores = _porCategoria.then((d) async => (d, await _colores));

  Future<Map<String, Color>> _calcularColores() async {
    final nombres = <String>{};
    // Si una consulta falla, se usan las categorías de la otra.
    try {
      nombres.addAll((await _porMes).map((s) => s.nombre));
    } catch (_) {}
    try {
      nombres.addAll((await _porCategoria).map((d) => d.categoria));
    } catch (_) {}
    return ColoresGraficas.porCategoria(nombres);
  }

  /// false = vista clásica (las dos gráficas de siempre), true = vista 3D.
  bool _vista3d = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const EncabezadoAzul(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Text('Gráficos\nventas y más',
                      style: GoogleFonts.archivoBlack(
                          color: AppColors.azulTitulo, fontSize: 28, height: 1.2)),
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    style: estiloSegmentos3D(context),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Vista clásica')),
                      ButtonSegment(value: true, label: Text('Vista 3D')),
                    ],
                    selected: {_vista3d},
                    onSelectionChanged: (s) =>
                        setState(() => _vista3d = s.first),
                  ),
                  const SizedBox(height: 22),
                  // Vista 3D: recibe los MISMOS Future que la vista clásica
                  // (mismos datos ya cargados y mismo mapa de colores).
                  if (_vista3d)
                    Vista3D(
                      porMes: _mesConColores,
                      porCategoria: _categoriaConColores,
                    )
                  else ...[
                  _TarjetaGrafica(
                    alto: 250,
                    child: FutureBuilder<
                        (List<SerieVentas>, Map<String, Color>)>(
                      future: _mesConColores,
                      builder: (_, snap) =>
                          _contenido(snap, (r) => _lineas(r.$1, r.$2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TarjetaGrafica(
                    alto: 560,
                    child: FutureBuilder<
                        (List<VentaCategoria>, Map<String, Color>)>(
                      future: _categoriaConColores,
                      builder: (_, snap) =>
                          _contenido(snap, (r) => _barras(r.$1, r.$2)),
                    ),
                  ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra cargando / error / gráfica según el estado del Future.
  Widget _contenido<T>(AsyncSnapshot<T> snap, Widget Function(T) construir) {
    if (snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError || snap.data == null) {
      return const Center(child: Text('No se pudieron cargar los datos'));
    }
    return construir(snap.data as T);
  }

  /// Gráfica 1: líneas, ventas por mes y categoría.
  Widget _lineas(List<SerieVentas> series, Map<String, Color> colores) {
    if (series.isEmpty) {
      return const Center(child: Text('Aún no hay ventas para graficar'));
    }
    return SfCartesianChart(
      title: const ChartTitle(text: 'Ventas por mes'),
      legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          overflowMode: LegendItemOverflowMode.wrap),
      tooltipBehavior: TooltipBehavior(enable: true),
      primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
      primaryYAxis: const NumericAxis(title: AxisTitle(text: 'Unidades')),
      series: series
          .map((s) => LineSeries<PuntoVenta, String>(
                name: s.nombre,
                color: colores[s.nombre],
                dataSource: s.puntos,
                xValueMapper: (p, _) => p.mes,
                yValueMapper: (p, _) => p.unidades,
                markerSettings: const MarkerSettings(isVisible: true),
              ))
          .toList(),
    );
  }

  /// Gráfica 2: barras horizontales, total por categoría (de mayor a menor).
  Widget _barras(List<VentaCategoria> datos, Map<String, Color> colores) {
    if (datos.isEmpty) {
      return const Center(child: Text('Aún no hay ventas para graficar'));
    }
    final ordenados = [...datos]..sort((a, b) => b.unidades.compareTo(a.unidades));
    return SfCartesianChart(
      title: const ChartTitle(text: 'Ventas por categoría'),
      tooltipBehavior: TooltipBehavior(enable: true),
      // isInversed: la primera categoría (la mayor) queda arriba.
      primaryXAxis: const CategoryAxis(
          isInversed: true,
          interval: 1,
          majorGridLines: MajorGridLines(width: 0)),
      primaryYAxis: const NumericAxis(
          title: AxisTitle(text: 'Unidades'),
          rangePadding: ChartRangePadding.additional),
      series: <CartesianSeries<VentaCategoria, String>>[
        BarSeries<VentaCategoria, String>(
          name: 'Unidades',
          dataSource: ordenados,
          xValueMapper: (d, _) => d.categoria,
          yValueMapper: (d, _) => d.unidades,
          pointColorMapper: (d, _) => colores[d.categoria],
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class _TarjetaGrafica extends StatelessWidget {
  final double alto;
  final Widget child;

  const _TarjetaGrafica({required this.alto, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.campoClaro,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(4, 6)),
        ],
      ),
      child: Container(
        height: alto,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}