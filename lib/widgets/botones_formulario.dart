import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Fila Cancelar / Guardar de los formularios.
class BotonesFormulario extends StatelessWidget {
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  const BotonesFormulario(
      {super.key, required this.onCancelar, required this.onGuardar});

  ButtonStyle _estilo(Color fondo, Color texto) => ElevatedButton.styleFrom(
        backgroundColor: fondo,
        foregroundColor: texto,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    final texto = GoogleFonts.archivo(fontWeight: FontWeight.w800);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onCancelar,
            style: _estilo(AppColors.cancelar, AppColors.azulTitulo),
            child: Text('Cancelar', style: texto),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onGuardar,
            style: _estilo(AppColors.guardar, Colors.white),
            child: Text('Guardar', style: texto),
          ),
        ),
      ],
    );
  }
}
