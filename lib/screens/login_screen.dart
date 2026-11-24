import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/boton_google.dart';
import '../widgets/campo_auth.dart';
import '../widgets/auth/fondo_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _cargando = false;

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AppStore.instance
          .iniciarSesion(_correoCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (mounted) _mostrarError(mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarConGoogle() async {
    try {
      await AppStore.instance.iniciarConGoogle();
    } catch (e) {
      if (mounted) _mostrarError(mensajeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final xl = MediaQuery.sizeOf(context).width >= 1280;
    return Scaffold(
      backgroundColor: AppColors.fondoAuth,
      body: FondoAuth(
        formulario: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado del formulario
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.campoAuth,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.bordeAuth.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.lock_outline,
                      size: 20, color: AppColors.celesteLink),
                ),
              ),
              const SizedBox(height: 24),
              Text('Bienvenido de nuevo',
                  style: GoogleFonts.archivoBlack(
                      color: Colors.white,
                      fontSize: xl ? 32 : 28,
                      height: 1.25,
                      letterSpacing: -0.035 * (xl ? 32 : 28))),
              const SizedBox(height: 12),
              Text('Tu tienda, en un solo lugar. Inicia sesión para continuar.',
                  style: GoogleFonts.archivo(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 24 / 14)),
              const SizedBox(height: 36),
              CampoAuth(
                etiqueta: 'Correo',
                hint: 'tu@correo.com',
                icono: Icons.mail_outline,
                controller: _correoCtrl,
                teclado: TextInputType.emailAddress,
                validador: Validators.correo,
              ),
              const SizedBox(height: 20),
              CampoAuth(
                etiqueta: 'Contraseña',
                hint: 'Ingresa tu contraseña',
                icono: Icons.lock_outline,
                controller: _passCtrl,
                esPassword: true,
                validador: Validators.contrasena,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith(
                        (estados) => estados.contains(WidgetState.hovered) &&
                                !estados.contains(WidgetState.disabled)
                            ? AppColors.azulEncabezado
                            : AppColors.azulBoton),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _cargando
                        ? [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.3))),
                            const SizedBox(width: 12),
                            Text('Iniciando sesión…',
                                style: GoogleFonts.archivo(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ]
                        : [
                            Text('Iniciar sesión',
                                style: GoogleFonts.archivo(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 1,
                          color: AppColors.bordeAuth.withValues(alpha: 0.25))),
                  const SizedBox(width: 16),
                  Text('o continúa con',
                      style: GoogleFonts.archivo(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Container(
                          height: 1,
                          color: AppColors.bordeAuth.withValues(alpha: 0.25))),
                ],
              ),
              const SizedBox(height: 28),
              BotonGoogle(
                  texto: 'Continuar con Google', onPressed: _iniciarConGoogle),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('¿No tienes cuenta?',
                      style: GoogleFonts.archivo(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.registro),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 12),
                        child: Text('Regístrate',
                            style: GoogleFonts.archivo(
                                color: AppColors.celesteLink,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}