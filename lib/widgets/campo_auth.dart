import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Campo de texto con etiqueta, estilo login/registro.
class CampoAuth extends StatefulWidget {
  final String etiqueta;
  final String hint;
  final TextEditingController controller;
  final bool esPassword;
  final TextInputType teclado;
  final String? Function(String?)? validador;

  const CampoAuth({
    super.key,
    required this.etiqueta,
    required this.hint,
    required this.controller,
    this.esPassword = false,
    this.teclado = TextInputType.text,
    this.validador,
  });

  @override
  State<CampoAuth> createState() => _CampoAuthState();
}

class _CampoAuthState extends State<CampoAuth> {
  bool _oculto = true;

  OutlineInputBorder _borde(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.etiqueta,
            style: GoogleFonts.archivo(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.esPassword && _oculto,
          keyboardType: widget.teclado,
          validator: widget.validador,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppColors.campoAuth,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            errorStyle: const TextStyle(color: AppColors.errorClaro),
            border: _borde(AppColors.bordeAuth),
            enabledBorder: _borde(AppColors.bordeAuth.withOpacity(0.6)),
            focusedBorder: _borde(AppColors.celesteLink),
            errorBorder: _borde(AppColors.errorClaro),
            focusedErrorBorder: _borde(AppColors.errorClaro),
            suffixIcon: widget.esPassword
                ? IconButton(
                    icon: Icon(
                        _oculto ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                        size: 20),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
