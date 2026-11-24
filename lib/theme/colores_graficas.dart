import 'package:flutter/material.dart';

/// Color fijo por categoría, compartido por la vista clásica y la vista 3D
/// de "Gráficos de ventas y más".
class ColoresGraficas {
  ColoresGraficas._();

  /// 16 colores distinguibles; arranca con el azul de la app y los 4 de antes.
  static const paleta = [
    Color(0xFF0B3A9B), // azul app
    Color(0xFF29B6F6), // celeste
    Color(0xFFFFB300), // ámbar
    Color(0xFFD64550), // rojo
    Color(0xFF2E7D32), // verde
    Color(0xFF8E24AA), // morado
    Color(0xFFF4511E), // naranja
    Color(0xFF00897B), // verde azulado
    Color(0xFF5C6BC0), // índigo
    Color(0xFFC2185B), // fucsia
    Color(0xFF7CB342), // verde lima
    Color(0xFF6D4C41), // café
    Color(0xFF0097A7), // cian
    Color(0xFF9E9D24), // oliva
    Color(0xFF37474F), // gris pizarra
    Color(0xFF90A4AE), // gris azulado
  ];

  /// Ordena alfabéticamente (sin distinguir mayúsculas) todas las categorías
  /// y le da a cada una el color de la paleta según ese orden.
  static Map<String, Color> porCategoria(Iterable<String> nombres) {
    final orden = nombres.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {
      for (var i = 0; i < orden.length; i++)
        orden[i]: paleta[i % paleta.length],
    };
  }
}
