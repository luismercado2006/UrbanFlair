import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../logo_recortado.dart';

/// Columna izquierda del login/registro en pantallas anchas (>= 1024).
class PanelMarca extends StatelessWidget {
  const PanelMarca({super.key});

  static const _beneficios = [
    (
      Icons.inventory_2_outlined,
      'Inventario en tiempo real',
      'Cada prenda, cada talla. Todo bajo control.',
    ),
    (
      Icons.insights_outlined,
      'Registro de ventas y gráficas',
      'Mira cómo se mueve tu tienda mes a mes.',
    ),
    (
      Icons.auto_awesome_outlined,
      'Predicción con IA',
      'Decisiones inteligentes para crecer.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final xl = MediaQuery.sizeOf(context).width >= 1280;
    final margenX = xl ? 88.0 : 48.0;
    final tamTitulo = xl ? 46.0 : 38.0;

    final contenido = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LogoRecortado(ancho: 202),
        const SizedBox(height: 56),
        Row(
          children: [
            Container(width: 28, height: 1, color: AppColors.celesteLink),
            const SizedBox(width: 12),
            Text('TU ESTILO. TU NEGOCIO.',
                style: GoogleFonts.archivo(
                    color: AppColors.celesteLink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4)),
          ],
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text.rich(
            TextSpan(
              text: 'Gestión inteligente\npara tu tienda\n',
              children: const [
                TextSpan(
                    text: 'urbana.',
                    style: TextStyle(color: AppColors.celesteLink)),
              ],
            ),
            style: GoogleFonts.archivoBlack(
                color: Colors.white,
                fontSize: tamTitulo,
                height: 1.18,
                letterSpacing: -0.035 * tamTitulo),
          ),
        ),
        const SizedBox(height: 44),
        for (var i = 0; i < _beneficios.length; i++) ...[
          if (i > 0) const SizedBox(height: 28),
          _beneficio(_beneficios[i].$1, _beneficios[i].$2, _beneficios[i].$3),
        ],
      ],
    );

    final pie = Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: AppColors.celesteLink, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text('Urban Flair · Hecho para impulsar tu negocio',
              style: GoogleFonts.archivo(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: margenX, vertical: 80),
                    child: Align(
                        alignment: Alignment.centerLeft, child: contenido),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(margenX, 0, margenX, 36),
                  child: pie,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _beneficio(IconData icono, String titulo, String descripcion) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.campoAuth.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.bordeAuth.withValues(alpha: 0.35)),
          ),
          child: Icon(icono, size: 20, color: AppColors.celesteLink),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: GoogleFonts.archivo(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(descripcion,
                  style: GoogleFonts.archivo(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 20 / 14)),
            ],
          ),
        ),
      ],
    );
  }
}
