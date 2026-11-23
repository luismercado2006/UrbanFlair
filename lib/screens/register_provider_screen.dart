import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../models/proveedor.dart';
import '../theme/app_colors.dart';
import '../utils/navegacion.dart';
import '../utils/validators.dart';
import '../widgets/botones_formulario.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/encabezado_azul.dart';

class RegisterProviderScreen extends StatefulWidget {
  const RegisterProviderScreen({super.key});

  @override
  State<RegisterProviderScreen> createState() => _RegisterProviderScreenState();
}

class _RegisterProviderScreenState extends State<RegisterProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final proveedor = Proveedor(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
    );
    try {
      await AppStore.instance.agregarProveedor(proveedor);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Proveedor guardado')));
      volverAlHome(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const EncabezadoAzul(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Registrar Proveedor',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.archivo(
                              color: AppColors.azulTitulo,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                      const SizedBox(height: 18),
                      CampoFormulario(
                          etiqueta: 'Nombre',
                          hint: 'Ingrese Nombre',
                          controller: _nombreCtrl),
                      const SizedBox(height: 16),
                      CampoFormulario(
                          etiqueta: 'Apellido',
                          hint: 'Ingrese Apellido',
                          controller: _apellidoCtrl),
                      const SizedBox(height: 16),
                      CampoFormulario(
                          etiqueta: 'Email',
                          hint: 'Ejemplo@Gmail.Com',
                          controller: _emailCtrl,
                          teclado: TextInputType.emailAddress,
                          validador: Validators.correo),
                      const SizedBox(height: 16),
                      CampoFormulario(
                          etiqueta: 'Teléfono',
                          hint: '+57',
                          controller: _telefonoCtrl,
                          teclado: TextInputType.phone,
                          validador: Validators.telefono),
                      const SizedBox(height: 16),
                      CampoFormulario(
                          etiqueta: 'Dirección',
                          hint: 'Ingrese Dirección',
                          controller: _direccionCtrl),
                      const SizedBox(height: 26),
                      BotonesFormulario(
                        onCancelar: () => volverAlHome(context),
                        onGuardar: _guardar,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}