import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Un mes con sus unidades (histórico o predicho).
class PuntoMes {
  final String mes;
  final double unidades;
  const PuntoMes(this.mes, this.unidades);
}

class ResultadoPrediccion {
  final String categoria;
  final List<PuntoMes> historial;
  final List<PuntoMes> prediccion;
  final List<int> arquitectura; // neuronas por capa oculta elegidas por la red
  final double errorMedio; // MAE en validación (unidades)
  final double errorReferencia; // MAE de repetir el mes anterior
  final int mesesHistoria;

  const ResultadoPrediccion({
    required this.categoria,
    required this.historial,
    required this.prediccion,
    required this.arquitectura,
    required this.errorMedio,
    required this.errorReferencia,
    required this.mesesHistoria,
  });

  factory ResultadoPrediccion.fromJson(Map<String, dynamic> j) {
    List<PuntoMes> puntos(List l) => [
          for (final e in l)
            PuntoMes(e['mes'] as String, (e['unidades'] as num).toDouble())
        ];
    final m = j['metricas'] as Map<String, dynamic>;
    return ResultadoPrediccion(
      categoria: j['categoria'] as String,
      historial: puntos(j['historial'] as List),
      prediccion: puntos(j['prediccion'] as List),
      arquitectura: [for (final n in m['arquitectura'] as List) n as int],
      errorMedio: (m['error_medio'] as num).toDouble(),
      errorReferencia: (m['error_referencia'] as num).toDouble(),
      mesesHistoria: m['meses_historia'] as int,
    );
  }
}

/// Cliente del backend Python (backend/api.py).
class PrediccionApi {
  /// Chrome/escritorio usan localhost; el emulador de Android usa 10.0.2.2.
  /// TODO(backend): cambiar por la URL en la nube cuando despliegues.
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  Future<List<String>> categorias() async {
    final r = await http
        .get(Uri.parse('$baseUrl/categorias'))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('Servidor respondió ${r.statusCode}');
    return [for (final c in jsonDecode(utf8.decode(r.bodyBytes)) as List) '$c'];
  }

  Future<ResultadoPrediccion> predecir(String categoria, int meses) async {
    final uri = Uri.parse('$baseUrl/predecir').replace(
        queryParameters: {'categoria': categoria, 'meses': '$meses'});
    final r = await http.get(uri).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('Servidor respondió ${r.statusCode}');
    return ResultadoPrediccion.fromJson(
        jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
  }
}