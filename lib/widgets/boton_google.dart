import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BotonGoogle extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const BotonGoogle({super.key, required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono provisional de Google. Si quieres el logo real, agrega
            // assets/images/google.png y cámbialo por Image.asset(...).
            const Icon(Icons.g_mobiledata, size: 32, color: Color(0xFF4285F4)),
            const SizedBox(width: 6),
            Text(texto,
                style: GoogleFonts.archivo(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
