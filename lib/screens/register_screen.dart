import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/boton_google.dart';
import '../widgets/campo_auth.dart';
import '../widgets/urban_flair_logo.dart';

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
                      const Center(child: UrbanFlairLogo(height: 56)),
                      const SizedBox(height: 10),
                      Text('Crear Cuenta',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.archivoBlack(
                              color: Colors.white, fontSize: 30)),
                      const SizedBox(height: 18),
                      CampoAuth(
                        etiqueta: 'Nombre',
                        hint: 'Ingrese Nombre',
                        controller: _nombreCtrl,
                        validador: (v) => Validators.requerido(v, 'El nombre'),
                      ),
                      const SizedBox(height: 12),
                      CampoAuth(
                        etiqueta: 'Apellido',
                        hint: 'Ingrese Apellido',
                        controller: _apellidoCtrl,
                        validador: (v) =>
                            Validators.requerido(v, 'El apellido'),
                      ),
                      const SizedBox(height: 12),
                      CampoAuth(
                        etiqueta: 'Correo Electrónico',
                        hint: 'Ejemplo@Gmail.Com',
                        controller: _correoCtrl,
                        teclado: TextInputType.emailAddress,
                        validador: Validators.correo,
                      ),
                      const SizedBox(height: 12),
                      CampoAuth(
                        etiqueta: 'Contraseña',
                        hint: '••••••',
                        controller: _passCtrl,
                        esPassword: true,
                        validador: Validators.contrasena,
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: SizedBox(
                          width: 140,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _registrarse,
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
                                : Text('Registrarse',
                                    style: GoogleFonts.archivo(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('O Continuar Con...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.archivo(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                      const SizedBox(height: 12),
                      BotonGoogle(
                          texto: 'Registrarse Con Google',
                          onPressed: _registrarConGoogle),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿Ya Tienes Cuenta? ',
                              style: GoogleFonts.archivo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.login),
                            child: Text('Inicia Sesión',
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