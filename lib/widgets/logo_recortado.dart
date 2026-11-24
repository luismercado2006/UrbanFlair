import 'package:flutter/material.dart';

import 'urban_flair_logo.dart';

/// Muestra [UrbanFlairLogo] recortando el margen transparente del PNG
/// (el dibujo ocupa ~48% del ancho y ~38% del alto de la imagen).
/// Se indica el tamaño VISIBLE del logo con [ancho] o con [alto].
class LogoRecortado extends StatelessWidget {
  // Fracción visible de la imagen y posición del recorte.
  static const double _fraccionAncho = 0.49;
  static const double _fraccionAlto = 0.39;
  static const Alignment _alineacion = Alignment(-0.024, -0.064);

  final double? ancho;
  final double? alto;
  final bool sobreOscuro;

  const LogoRecortado({
    super.key,
    this.ancho,
    this.alto,
    this.sobreOscuro = true,
  }) : assert(ancho != null || alto != null);

  @override
  Widget build(BuildContext context) {
    final lado = ancho != null ? ancho! / _fraccionAncho : alto! / _fraccionAlto;
    return SizedBox(
      width: lado * _fraccionAncho,
      height: lado * _fraccionAlto,
      child: ClipRect(
        child: OverflowBox(
          minWidth: lado,
          maxWidth: lado,
          minHeight: lado,
          maxHeight: lado,
          alignment: _alineacion,
          child: UrbanFlairLogo(height: lado, sobreOscuro: sobreOscuro),
        ),
      ),
    );
  }
}
