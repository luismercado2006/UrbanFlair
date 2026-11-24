import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Crema de la "G" del diseño (no existe en AppColors).
const Color _cremaG = Color(0xFFF1EDE0);

class BotonGoogle extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const BotonGoogle({super.key, required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((estados) => BorderSide(
              color: Colors.white.withValues(
                  alpha: estados.contains(WidgetState.hovered) ? 0.5 : 0.25))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('G',
                style: GoogleFonts.archivo(
                    color: _cremaG, fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(texto,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.archivo(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
