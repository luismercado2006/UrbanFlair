import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../theme/app_colors.dart';
import '../utils/navegacion.dart';
import '../widgets/encabezado_azul.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = AppStore.instance.usuario;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const EncabezadoAzul(titulo: 'Mi Perfil'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: AppColors.azulEncabezado,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline,
                            size: 110, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CampoLectura('Nombre', u?.nombre ?? '', 'Nombre'),
                    _CampoLectura('Apellido', u?.apellido ?? '', 'Apellido'),
                    _CampoLectura('Correo', u?.correo ?? '', 'Ejemplo@Gmail.Com'),
                    _CampoLectura('Rol', u?.rol ?? '', 'Rol'),
                    const SizedBox(height: 18),
                    Center(
                      child: SizedBox(
                        width: 170,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => cerrarSesion(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rojoCerrar,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Cerrar Sesión',
                              style: GoogleFonts.archivo(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de solo lectura: muestra el valor o, si está vacío, el texto guía.
class _CampoLectura extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String hint;

  const _CampoLectura(this.etiqueta, this.valor, this.hint);

  @override
  Widget build(BuildContext context) {
    final vacio = valor.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(etiqueta,
                style: GoogleFonts.archivo(
                    color: AppColors.azulTitulo,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.campoClaro,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 8, offset: Offset(3, 5)),
              ],
            ),
            child: Text(vacio ? hint : valor,
                style: GoogleFonts.archivo(
                    color: vacio ? AppColors.textoGris : Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
