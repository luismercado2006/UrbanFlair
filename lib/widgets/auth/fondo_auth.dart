import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../logo_recortado.dart';
import 'panel_marca.dart';

/// Fondo y distribución del login/registro.
/// - Ancho >= 1024: degradado diagonal, panel de marca (55%) + formulario (45%).
/// - Ancho < 1024: degradado vertical, logo arriba y formulario debajo.
class FondoAuth extends StatelessWidget {
  final Widget formulario;

  const FondoAuth({super.key, required this.formulario});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final ancha = ancho >= 1024;
    final xl = ancho >= 1280;

    final pie = Text(
      '© ${DateTime.now().year} Urban Flair. Todos los derechos reservados.',
      textAlign: TextAlign.center,
      style: GoogleFonts.archivo(
          color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
    );

    final Widget contenido;
    if (ancha) {
      contenido = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 55, child: PanelMarca()),
          Expanded(
            flex: 45,
            // El pie queda abajo si hay espacio; si el formulario no cabe,
            // va después de él dentro del scroll (no se superponen).
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: xl ? 48 : 32),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: math.max(0, c.maxHeight - 52)),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: formulario,
                          ),
                        ),
                      ),
                    ),
                    pie,
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final margenX = ancho >= 800 ? 48.0 : 24.0;
      contenido = SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: margenX, vertical: 40),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: math.max(0, c.maxHeight - 80)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LogoRecortado(ancho: 112),
                  const SizedBox(height: 40),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: formulario,
                  ),
                  const SizedBox(height: 56),
                  pie,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: ancha ? Alignment.topLeft : Alignment.topCenter,
          end: ancha ? Alignment.bottomRight : Alignment.bottomCenter,
          colors: const [AppColors.fondoAuth, AppColors.tarjetaAuth],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _LineasDecorativas()),
            ),
          ),
          Positioned.fill(child: contenido),
        ],
      ),
    );
  }
}

/// Círculos y rectángulo redondeado rotado del diseño (borde #1E88E5 al 10%).
class _LineasDecorativas extends CustomPainter {
  const _LineasDecorativas();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.bordeAuth.withValues(alpha: 0.1);

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Rectángulo de 820 px, left 28%, bottom -288, rotado -28°.
    canvas.save();
    canvas.translate(size.width * 0.28 + 410, size.height + 288 - 410);
    canvas.rotate(-28 * math.pi / 180);
    for (final (inset, radio) in const [
      (0.0, 110.0),
      (56.0, 84.0),
      (112.0, 62.0),
      (160.0, 42.0),
    ]) {
      final lado = 820 - inset * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: lado, height: lado),
          Radius.circular(radio),
        ),
        p,
      );
    }
    canvas.restore();

    // Círculo superior izquierdo (680 px, left -176, top -256).
    canvas.drawCircle(const Offset(-176 + 340, -256 + 340), 340, p);
    // Círculo derecho (720 px, right -288, top 12%).
    canvas.drawCircle(
        Offset(size.width + 288 - 360, size.height * 0.12 + 360), 360, p);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LineasDecorativas oldDelegate) => false;
}
