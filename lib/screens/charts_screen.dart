import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../data/ventas_repositorio.dart';
import '../models/datos_graficas.dart';
import '../theme/app_colors.dart';
import '../widgets/encabezado_azul.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  static const _paleta = [
    Color(0xFF0B3A9B),
    Color(0xFF29B6F6),
    Color(0xFFFFB300),
    Color(0xFFD64550),
  ];

  final _repo = VentasRepositorio();
  late final Future<List<SerieVentas>> _porMes = _repo.ventasPorMes();
  late final Future<List<VentaCategoria>> _porCategoria =
      _repo.ventasPorCategoria();

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
                  const SizedBox(height: 22),
                  _TarjetaGrafica(
                    alto: 250,
                    child: FutureBuilder<List<SerieVentas>>(
                      future: _porMes,
                      builder: (_, snap) => _contenido(snap, _lineas),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TarjetaGrafica(
                    alto: 300,
                    child: FutureBuilder<List<VentaCategoria>>(
                      future: _porCategoria,
                      builder: (_, snap) => _contenido(snap, _radial),
                    ),
                  ),
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
  Widget _lineas(List<SerieVentas> series) {
    if (series.isEmpty) {
      return const Center(child: Text('Aún no hay ventas para graficar'));
    }
    return SfCartesianChart(
      title: const ChartTitle(text: 'Ventas por mes'),
      palette: _paleta,
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
                dataSource: s.puntos,
                xValueMapper: (p, _) => p.mes,
                yValueMapper: (p, _) => p.unidades,
                markerSettings: const MarkerSettings(isVisible: true),
              ))
          .toList(),
    );
  }

  /// Gráfica 2: anillos concentrados, total por categoría.
  /// (Syncfusion Flutter no trae gráfica polar; el radial es lo más parecido.)
  Widget _radial(List<VentaCategoria> datos) {
    if (datos.isEmpty) {
      return const Center(child: Text('Aún no hay ventas para graficar'));
    }
    final maximo =
        datos.map((d) => d.unidades).reduce((a, b) => a > b ? a : b) * 1.2;
    return SfCircularChart(
      title: const ChartTitle(text: 'Ventas por categoría'),
      palette: _paleta,
      legend: const Legend(
          isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries<VentaCategoria, String>>[
        RadialBarSeries<VentaCategoria, String>(
          dataSource: datos,
          xValueMapper: (d, _) => d.categoria,
          yValueMapper: (d, _) => d.unidades,
          maximumValue: maximo,
          cornerStyle: CornerStyle.bothCurve,
          radius: '90%',
          gap: '8%',
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