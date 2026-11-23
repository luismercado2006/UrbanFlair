import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

// ─────────────────────────── CONFIGURACIÓN ───────────────────────────
/// Si pruebas en un celular físico, cambia esto por la IP de tu PC,
/// por ejemplo 'http://192.168.1.20:8000'.
const String? kUrlManual = null;

/// true  -> el botón reentrena la red (tarda) y luego predice.
/// false -> el botón solo predice con el modelo ya entrenado (rápido).
const bool kReentrenarAlPredecir = false;

const Color kAzul = Color(0xFF0D47A1);
const Color kAzulClaro = Color(0xFFE8F4FD);
const Color kVerde = Color(0xFF28A745);
const Color kNaranja = Color(0xFFF57C00);
const Color kFondoTarjeta = Color(0xFFF0F3FA);

String get _baseUrl {
  if (kUrlManual != null) return kUrlManual!;
  if (kIsWeb) return 'http://localhost:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000'; // emulador Android
  }
  return 'http://localhost:8000';
}

// ─────────────────────────── UTILIDADES ───────────────────────────
const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

/// '2026-11' -> 'nov 2026'
String _fechaCorta(String f) {
  final p = f.split('-');
  return '${_meses[int.parse(p[1]) - 1]} ${p[0]}';
}

/// 3296.5 -> '3.296,5' (formato español). Quita el decimal si es .0
String _num(num v, {int dec = 1}) {
  final s = v.toStringAsFixed(dec);
  final partes = s.split('.');
  final ent = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  if (partes.length == 1 || int.parse(partes[1]) == 0) return ent;
  return '$ent,${partes[1]}';
}

class _Punto {
  _Punto(this.x, this.y);
  final String x;
  final double y;
}

class _PuntoNum {
  _PuntoNum(this.x, this.y);
  final double x;
  final double y;
}

// ─────────────────────────── PANTALLA ───────────────────────────
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _mesesCtrl = TextEditingController(text: '6');
  List<String> _categorias = [];
  String? _seleccion;
  bool _cargando = false;
  String? _error;
  Map<String, dynamic>? _res;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _mesesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final r = await http
          .get(Uri.parse('$_baseUrl/categorias'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) throw Exception('Error ${r.statusCode}');
      final lista = (jsonDecode(utf8.decode(r.bodyBytes)) as List)
          .map((e) => e.toString())
          .toList();
      setState(() {
        _categorias = lista;
        _seleccion = lista.isNotEmpty ? lista.first : null;
      });
    } catch (e) {
      setState(() => _error =
          'No se pudo conectar con el servidor ($_baseUrl). '
          '¿Está corriendo uvicorn?');
    }
  }

  Future<void> _predecir() async {
    final meses = int.tryParse(_mesesCtrl.text.trim());
    if (_seleccion == null) return;
    if (meses == null || meses < 1 || meses > 24) {
      setState(() => _error = 'Ingresa un número de meses entre 1 y 24.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      if (kReentrenarAlPredecir) {
        await http
            .post(Uri.parse('$_baseUrl/reentrenar'))
            .timeout(const Duration(minutes: 5));
      }
      final uri = Uri.parse('$_baseUrl/predecir').replace(
          queryParameters: {'categoria': _seleccion!, 'meses': '$meses'});
      final r = await http.get(uri).timeout(const Duration(seconds: 60));
      if (r.statusCode != 200) throw Exception('Error ${r.statusCode}');
      setState(() =>
          _res = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
    } catch (e) {
      setState(() => _error = 'No se pudo obtener la predicción: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ─────────────────────────── UI ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        foregroundColor: Colors.white,
        title: const Text(
          'Red Neuronal (Keras) - Predicción de Productos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 16),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Predicción con Red Neuronal',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6EFD)),
                  ),
                  const Divider(color: Color(0xFF0D6EFD), thickness: 2),
                  const SizedBox(height: 6),
                  const Text(
                    'Elige un producto y cuántos meses quieres predecir '
                    'a partir de las ventas registradas.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  _formulario(),
                  const SizedBox(height: 16),
                  _botonPredecir(),
                  const SizedBox(height: 16),
                  _tarjetaResultado(),
                  if (_res != null) ...[
                    const SizedBox(height: 16),
                    _metricas(),
                    const SizedBox(height: 20),
                    _graficaPrediccion(),
                    const SizedBox(height: 12),
                    _prediccionMensual(),
                    const SizedBox(height: 12),
                    _arquitectura(),
                    const SizedBox(height: 20),
                    _graficaPerdida(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    final dropdown = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Producto:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _seleccion,
          isExpanded: true,
          decoration: _decoracionCampo(),
          items: _categorias
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _seleccion = v),
        ),
      ],
    );
    final meses = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meses a predecir (1 a 24):',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _mesesCtrl,
          keyboardType: TextInputType.number,
          decoration: _decoracionCampo(),
        ),
      ],
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 560) {
        return Column(children: [dropdown, const SizedBox(height: 12), meses]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: dropdown),
        const SizedBox(width: 16),
        Expanded(flex: 1, child: meses),
      ]);
    });
  }

  InputDecoration _decoracionCampo() => InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
      );

  Widget _botonPredecir() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_cargando || _seleccion == null) ? null : _predecir,
        style: ElevatedButton.styleFrom(
          backgroundColor: kVerde,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Text('Entrenar red y predecir',
                style: TextStyle(fontSize: 17)),
      ),
    );
  }

  Widget _tarjetaResultado() {
    Widget contenido;
    if (_error != null) {
      contenido = Text(_error!,
          style: const TextStyle(color: Colors.red, fontSize: 16));
    } else if (_res == null) {
      contenido = const Text('Selecciona un producto y presiona el botón...',
          style: TextStyle(fontSize: 17));
    } else {
      final pred = (_res!['prediccion'] as List);
      final total = (_res!['total_unidades'] as num).toDouble();
      final desde = _fechaCorta(pred.first['fecha'] as String);
      contenido = Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              kReentrenarAlPredecir
                  ? 'Entrenamiento completado para:'
                  : 'Predicción completada para:',
              style: const TextStyle(
                  color: Color(0xFF1E7E34), fontSize: 17),
            ),
          ),
          const SizedBox(height: 12),
          Text(_res!['categoria'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kAzul, fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 17, color: Colors.black54),
              children: [
                TextSpan(
                    text: 'Unidades estimadas desde $desde, '
                        'en los próximos ${pred.length} meses: '),
                TextSpan(
                    text: '${_num(total)} unidades',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kAzulClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0D6EFD)),
      ),
      child: contenido,
    );
  }

  Widget _metricas() {
    final m = _res!['metricas'] as Map<String, dynamic>;
    final pred = _res!['prediccion'] as List;
    final items = <List<String>>[
      ['Error promedio (MAE)', '${_num(m['error_medio'] as num)} und'],
      ['Error porcentual (MAPE)', '${_num(m['mape'] as num)} %'],
      ['Meses de historial', '${m['meses_historia']}'],
      ['Meses predichos', '${pred.length}'],
      ['Iteraciones', '${m['iteraciones']}'],
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((e) => Container(
                width: 160,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: kFondoTarjeta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(e[0],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(e[1],
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kAzul)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _graficaPrediccion() {
    final hist = (_res!['historial'] as List);
    final pred = (_res!['prediccion'] as List);

    final real = hist
        .map((e) => _Punto(_fechaCorta(e['fecha'] as String),
            (e['unidades'] as num).toDouble()))
        .toList();
    final futuro = pred
        .map((e) => _Punto(_fechaCorta(e['fecha'] as String),
            (e['unidades'] as num).toDouble()))
        .toList();
    // Une la línea punteada con el último punto real
    final conectada = [real.last, ...futuro];

    return Column(
      children: [
        const Text('Ventas mensuales: real vs. predicción (unidades)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(
          height: 320,
          child: SfCartesianChart(
            legend: const Legend(
                isVisible: true, position: LegendPosition.top),
            tooltipBehavior: TooltipBehavior(enable: true),
            primaryXAxis: const CategoryAxis(
              labelRotation: -30,
              majorGridLines: MajorGridLines(width: 0.5),
              title: AxisTitle(text: 'Mes'),
            ),
            primaryYAxis: const NumericAxis(
              minimum: 0,
              title: AxisTitle(text: 'Unidades'),
            ),
            series: <CartesianSeries<_Punto, String>>[
              LineSeries<_Punto, String>(
                name: 'Real',
                dataSource: real,
                xValueMapper: (p, _) => p.x,
                yValueMapper: (p, _) => p.y,
                color: kAzul,
                width: 3,
                markerSettings: const MarkerSettings(isVisible: true),
              ),
              LineSeries<_Punto, String>(
                name: 'Predicción',
                dataSource: conectada,
                xValueMapper: (p, _) => p.x,
                yValueMapper: (p, _) => p.y,
                color: kNaranja,
                width: 3,
                dashArray: const <double>[8, 5],
                markerSettings: const MarkerSettings(
                    isVisible: true, shape: DataMarkerType.diamond),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prediccionMensual() {
    final pred = (_res!['prediccion'] as List);
    final spans = <InlineSpan>[
      const TextSpan(
          text: 'Predicción mensual:\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
    ];
    for (var i = 0; i < pred.length; i++) {
      final e = pred[i];
      spans.add(TextSpan(text: '${_fechaCorta(e['fecha'] as String)}: '));
      spans.add(TextSpan(
          text: _num(e['unidades'] as num),
          style: const TextStyle(fontWeight: FontWeight.bold)));
      spans.add(const TextSpan(text: ' und'));
      if (i < pred.length - 1) spans.add(const TextSpan(text: '  ·  '));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kFondoTarjeta, borderRadius: BorderRadius.circular(12)),
      child: Text.rich(
        TextSpan(style: const TextStyle(fontSize: 15, color: Colors.black), children: spans),
      ),
    );
  }

  Widget _arquitectura() {
    final m = _res!['metricas'] as Map<String, dynamic>;
    final capas = (m['arquitectura'] as List)
        .map((n) => 'Dense $n')
        .join(' -> ');
    final nCat = _categorias.length - 1; // sin "Ventas totales"
    return Text(
      'Arquitectura: Keras Sequential: 2 entradas (ventas de los 2 meses '
      'anteriores) -> $capas -> 1 salida (ReLU, Adam, MSE, '
      '${m['iteraciones']} iteraciones, entrenada con las $nCat categorías)',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.black54, fontSize: 14),
    );
  }

  Widget _graficaPerdida() {
    final m = _res!['metricas'] as Map<String, dynamic>;
    final curva = (m['curva_perdida'] as List).map((e) => (e as num).toDouble()).toList();
    final datos = [
      for (var i = 0; i < curva.length; i++) _PuntoNum(i + 1.0, curva[i])
    ];
    return Column(
      children: [
        Text('Curva de aprendizaje de la red (${curva.length} iteraciones)',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black54)),
        SizedBox(
          height: 260,
          child: SfCartesianChart(
            legend: const Legend(
                isVisible: true, position: LegendPosition.top),
            primaryXAxis: const NumericAxis(
              minimum: 1,
              title: AxisTitle(text: 'Iteración'),
            ),
            primaryYAxis: const NumericAxis(
              minimum: 0,
              title: AxisTitle(text: 'Pérdida'),
            ),
            series: <CartesianSeries<_PuntoNum, double>>[
              LineSeries<_PuntoNum, double>(
                name: 'Pérdida durante el entrenamiento',
                dataSource: datos,
                xValueMapper: (p, _) => p.x,
                yValueMapper: (p, _) => p.y,
                color: const Color(0xFF2E7D32),
                width: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}