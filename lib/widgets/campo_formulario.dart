import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/validators.dart';

InputDecoration decoracionFormulario(String hint, {String? prefijo}) =>
    InputDecoration(
      hintText: hint,
      prefixText: prefijo,
      hintStyle: GoogleFonts.archivo(
          color: AppColors.textoGris, fontWeight: FontWeight.w700, fontSize: 13),
      filled: true,
      fillColor: AppColors.campoClaro,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );

Widget _etiqueta(String t) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(t,
          style: GoogleFonts.archivo(
              color: AppColors.azulTitulo,
              fontWeight: FontWeight.w800,
              fontSize: 14)),
    );

Widget _conSombra(Widget child) => Container(
      decoration: BoxDecoration(
        color: AppColors.campoClaro,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(3, 5)),
        ],
      ),
      child: child,
    );

/// Campo de texto con etiqueta y sombra (formularios internos).
class CampoFormulario extends StatelessWidget {
  final String etiqueta;
  final String hint;
  final TextEditingController controller;
  final TextInputType teclado;
  final String? Function(String?)? validador;
  final String? prefijo;

  const CampoFormulario({
    super.key,
    required this.etiqueta,
    required this.hint,
    required this.controller,
    this.teclado = TextInputType.text,
    this.validador,
    this.prefijo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(etiqueta),
        _conSombra(TextFormField(
          controller: controller,
          keyboardType: teclado,
          validator: validador ?? (v) => Validators.requerido(v, etiqueta),
          decoration: decoracionFormulario(hint, prefijo: prefijo),
        )),
      ],
    );
  }
}

/// Lista desplegable con etiqueta y sombra.
class ListaFormulario extends StatelessWidget {
  final String etiqueta;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const ListaFormulario({
    super.key,
    required this.etiqueta,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(etiqueta),
        _conSombra(DropdownButtonFormField<String>(
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          decoration: decoracionFormulario('Seleccione'),
          hint: Text('Seleccione',
              style: GoogleFonts.archivo(
                  color: AppColors.textoGris,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Seleccione' : null,
        )),
      ],
    );
  }
}
