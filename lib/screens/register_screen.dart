import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/boton_google.dart';
import '../widgets/campo_auth.dart';
import '../widgets/auth/fondo_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _cargando = false;

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AppStore.instance.registrar(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      _mostrarMensaje('Cuenta creada. Inicia sesión.');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      if (mounted) _mostrarMensaje(mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _registrarConGoogle() async {
    try {
      await AppStore.instance.iniciarConGoogle();
    } catch (e) {
      if (mounted) _mostrarMensaje(mensajeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    final xl = anchoPantalla >= 1280;

    final campoNombre = CampoAuth(
      etiqueta: 'Nombre',
      hint: 'Nombre',
      icono: Icons.person_outline,
      controller: _nombreCtrl,
      validador: (v) => Validators.requerido(v, 'El nombre'),
    );
    final campoApellido = CampoAuth(
      etiqueta: 'Apellido',
      hint: 'Apellido',
      icono: Icons.person_outline,
      controller: _apellidoCtrl,
      validador: (v) => Validators.requerido(v, 'El apellido'),
    );

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
                  child: const Icon(Icons.person_outline,
                      size: 20, color: AppColors.celesteLink),
                ),
              ),
              const SizedBox(height: 24),
              Text('Crea tu cuenta',
                  style: GoogleFonts.archivoBlack(
                      color: Colors.white,
                      fontSize: xl ? 32 : 28,
                      height: 1.25,
                      letterSpacing: -0.035 * (xl ? 32 : 28))),
              const SizedBox(height: 12),
              Text('Empieza a gestionar tu tienda con Urban Flair.',
                  style: GoogleFonts.archivo(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 24 / 14)),
              const SizedBox(height: 36),
              if (anchoPantalla < 360) ...[
                campoNombre,
                const SizedBox(height: 20),
                campoApellido,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: campoNombre),
                    const SizedBox(width: 16),
                    Expanded(child: campoApellido),
                  ],
                ),
              const SizedBox(height: 20),
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
                  onPressed: _cargando ? null : _registrarse,
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
                            Text('Creando cuenta…',
                                style: GoogleFonts.archivo(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ]
                        : [
                            Text('Crear cuenta',
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
                  texto: 'Continuar con Google',
                  onPressed: _registrarConGoogle),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('¿Ya tienes cuenta?',
                      style: GoogleFonts.archivo(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.login),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 12),
                        child: Text('Inicia sesión',
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