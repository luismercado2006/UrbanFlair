import 'package:flutter/material.dart';

/// ============================================================
///  ESPACIO PARA EL LOGO DE URBAN FLAIR
///  1) Copia tu logo a:  assets/images/logo_urban_flair.png
///  2) Verifica que pubspec.yaml declare:  assets/images/
///  Mientras el archivo no exista, se muestra un recuadro "LOGO".
///  Este widget se usa en las 4 pantallas, así que cambiar
///  [assetPath] aquí actualiza todas.
/// ============================================================
class UrbanFlairLogo extends StatelessWidget {
  static const String assetPath = 'assets/images/Logo_UrbanFlair.png';

  final double height;

  /// true cuando el logo va sobre fondo oscuro (el recuadro se ve claro).
  final bool sobreOscuro;

  const UrbanFlairLogo({super.key, this.height = 60, this.sobreOscuro = true});

  @override
  Widget build(BuildContext context) {
    final color = sobreOscuro ? Colors.white : const Color(0xFF0A3568);
    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: height * 1.3,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('LOGO',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
