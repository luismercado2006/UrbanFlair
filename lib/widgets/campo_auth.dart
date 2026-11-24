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
  final IconData? icono;

  const CampoAuth({
    super.key,
    required this.etiqueta,
    required this.hint,
    required this.controller,
    this.esPassword = false,
    this.teclado = TextInputType.text,
    this.validador,
    this.icono,
  });

  @override
  State<CampoAuth> createState() => _CampoAuthState();
}

class _CampoAuthState extends State<CampoAuth> {
  bool _oculto = true;

  OutlineInputBorder _borde(Color c, [double ancho = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: ancho),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.etiqueta,
            style: GoogleFonts.archivo(
                color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 10),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.esPassword && _oculto,
          keyboardType: widget.teclado,
          validator: widget.validador,
          cursorColor: AppColors.celesteLink,
          style: GoogleFonts.archivo(
              color: Colors.white, fontSize: 14, height: 1.2),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.archivo(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.2),
            filled: true,
            fillColor: AppColors.campoAuth,
            contentPadding: EdgeInsets.fromLTRB(
                widget.icono == null ? 16 : 0, 19.6, 16, 19.6),
            prefixIcon: widget.icono == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(widget.icono,
                        size: 20, color: AppColors.celesteLink),
                  ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            errorStyle: GoogleFonts.archivo(
                color: AppColors.errorClaro, fontSize: 14),
            errorMaxLines: 2,
            border: _borde(AppColors.bordeAuth.withValues(alpha: 0.35)),
            enabledBorder: _borde(AppColors.bordeAuth.withValues(alpha: 0.35)),
            focusedBorder: _borde(AppColors.celesteLink, 1.5),
            errorBorder: _borde(AppColors.errorClaro),
            focusedErrorBorder: _borde(AppColors.errorClaro, 1.5),
            suffixIcon: widget.esPassword
                ? IconButton(
                    icon: Icon(
                        _oculto
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withValues(alpha: 0.7),
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
