import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/boton_google.dart';
import '../widgets/campo_auth.dart';
import '../widgets/urban_flair_logo.dart';

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
    return Scaffold(
      backgroundColor: AppColors.fondoAuth,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.tarjetaAuth,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bordeAuth),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: UrbanFlairLogo(height: 64)),
                      const SizedBox(height: 12),
                      Text('Iniciar Sesión',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.archivoBlack(
                              color: Colors.white, fontSize: 32)),
                      const SizedBox(height: 22),
                      CampoAuth(
                        etiqueta: 'Correo',
                        hint: 'Ejemplo@Gmail.Com',
                        controller: _correoCtrl,
                        teclado: TextInputType.emailAddress,
                        validador: Validators.correo,
                      ),
                      const SizedBox(height: 18),
                      CampoAuth(
                        etiqueta: 'Contraseña',
                        hint: '••••••',
                        controller: _passCtrl,
                        esPassword: true,
                        validador: Validators.contrasena,
                      ),
                      const SizedBox(height: 26),
                      Center(
                        child: SizedBox(
                          width: 140,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azulBoton,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text('Iniciar Sesión',
                                    style: GoogleFonts.archivo(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('O Continuar Con...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.archivo(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                      const SizedBox(height: 14),
                      BotonGoogle(
                          texto: 'Iniciar Sesión Con Google',
                          onPressed: _iniciarConGoogle),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿No Tienes Cuenta? ',
                              style: GoogleFonts.archivo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.registro),
                            child: Text('Regístrate',
                                style: GoogleFonts.archivo(
                                    color: AppColors.celesteLink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}