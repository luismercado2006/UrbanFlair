import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../models/producto.dart';
import '../theme/app_colors.dart';
import '../utils/navegacion.dart';
import '../utils/validators.dart';
import '../widgets/botones_formulario.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/encabezado_azul.dart';

class RegisterProductScreen extends StatefulWidget {
  const RegisterProductScreen({super.key});

  @override
  State<RegisterProductScreen> createState() => _RegisterProductScreenState();
}

class _RegisterProductScreenState extends State<RegisterProductScreen> {
  // TODO(backend): categorías y tallas vendrán de la API.
  static const _categorias = ['Camisas', 'Pantalones', 'Chaquetas', 'Calzado', 'Accesorios'];
  static const _tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  // Mientras no haya proveedores registrados se usan estos de ejemplo.
  static const _proveedoresEjemplo = ['Proveedor 1', 'Proveedor 2', 'Proveedor 3'];

  final _store = AppStore.instance;
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  String? _categoria;
  String? _talla;
  String? _proveedor;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    try {
      await _store.cargarProveedores();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  List<String> get _proveedores {
    final registrados =
        _store.proveedores.map((p) => p.nombreCompleto).toSet().toList();
    return registrados.isEmpty ? _proveedoresEjemplo : registrados;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _colorCtrl.dispose();
    _marcaCtrl.dispose();
    _stockCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final producto = Producto(
      categoria: _categoria!,
      descripcion: _descripcionCtrl.text.trim(),
      color: _colorCtrl.text.trim(),
      talla: _talla!,
      marca: _marcaCtrl.text.trim(),
      stock: int.parse(_stockCtrl.text.trim()),
      valor: double.parse(_valorCtrl.text.trim().replaceAll(',', '.')),
      proveedor: _proveedor!,
    );
    try {
      await _store.agregarProducto(producto);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Producto guardado')));
      volverAlHome(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeError(e))));
    }
  }

  Widget _fila(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
          ],
        ),
      );

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
                    children: [
                      Text('Registrar Producto',
                          style: GoogleFonts.archivo(
                              color: AppColors.azulTitulo,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                      const SizedBox(height: 22),
                      _fila(
                        ListaFormulario(
                            etiqueta: 'Categoría',
                            items: _categorias,
                            onChanged: (v) => _categoria = v),
                        CampoFormulario(
                            etiqueta: 'Descripción',
                            hint: 'Ingrese Descrip...',
                            controller: _descripcionCtrl),
                      ),
                      _fila(
                        CampoFormulario(
                            etiqueta: 'Color',
                            hint: 'Rojo, Azul...',
                            controller: _colorCtrl),
                        ListaFormulario(
                            etiqueta: 'Talla',
                            items: _tallas,
                            onChanged: (v) => _talla = v),
                      ),
                      _fila(
                        CampoFormulario(
                            etiqueta: 'Marca',
                            hint: 'Ingrese Marca',
                            controller: _marcaCtrl),
                        CampoFormulario(
                            etiqueta: 'Stock',
                            hint: '0',
                            controller: _stockCtrl,
                            teclado: TextInputType.number,
                            validador: Validators.entero),
                      ),
                      _fila(
                        CampoFormulario(
                            etiqueta: 'Valor',
                            hint: '0.00',
                            controller: _valorCtrl,
                            teclado: const TextInputType.numberWithOptions(
                                decimal: true),
                            validador: Validators.valor,
                            prefijo: '\$'),
                        ListaFormulario(
                            etiqueta: 'Proveedor',
                            items: _proveedores,
                            onChanged: (v) => _proveedor = v),
                      ),
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