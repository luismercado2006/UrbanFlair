import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../theme/app_colors.dart';
import 'campo_formulario.dart';

String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

/// Cuadro para vender productos: elige producto y cantidad, agrega varias
/// líneas y confirma. Devuelve las líneas vendidas (o null si se cancela).
class NuevaVentaDialog extends StatefulWidget {
  const NuevaVentaDialog({super.key});

  static Future<List<ItemVenta>?> mostrar(BuildContext context) =>
      showDialog<List<ItemVenta>>(
        context: context,
        builder: (_) => const NuevaVentaDialog(),
      );

  @override
  State<NuevaVentaDialog> createState() => _NuevaVentaDialogState();
}

class _NuevaVentaDialogState extends State<NuevaVentaDialog> {
  final _store = AppStore.instance;
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final List<ItemVenta> _items = [];

  Producto? _seleccion;
  int _reinicio = 0; // cambia para limpiar el dropdown tras agregar

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  int _enCarrito(String codigo) => _items
      .where((i) => i.codigoProducto == codigo)
      .fold(0, (s, i) => s + i.cantidad);

  int _disponible(Producto p) => p.stock - _enCarrito(p.codigo);

  List<Producto> get _vendibles =>
      _store.productos.where((p) => _disponible(p) > 0).toList();

  double get _total => _items.fold(0.0, (s, i) => s + i.subtotal);

  void _agregar() {
    if (!_formKey.currentState!.validate()) return;
    final p = _seleccion!;
    final cantidad = int.parse(_cantidadCtrl.text.trim());
    final existente = _items.indexWhere((i) => i.codigoProducto == p.codigo);

    setState(() {
      final nuevo = ItemVenta(
        codigoProducto: p.codigo,
        descripcion: p.descripcion,
        cantidad: cantidad + (existente == -1 ? 0 : _items[existente].cantidad),
        valorUnitario: p.valor,
      );
      if (existente == -1) {
        _items.add(nuevo);
      } else {
        _items[existente] = nuevo;
      }
      _seleccion = null;
      _cantidadCtrl.clear();
      _reinicio++;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final estiloTitulo = GoogleFonts.archivo(
        color: AppColors.azulTitulo, fontWeight: FontWeight.w800, fontSize: 20);

    // Sin productos con stock: nada que vender todavía.
    if (_store.productos.every((p) => p.stock <= 0)) {
      return AlertDialog(
        title: Text('Nueva Venta', style: estiloTitulo),
        content: const Text(
            'No hay productos con stock. Registra productos antes de vender.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
        ],
      );
    }

    final seleccion = _seleccion;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Nueva Venta', style: estiloTitulo),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Producto>(
                      key: ValueKey(_reinicio),
                      isExpanded: true,
                      decoration: decoracionFormulario('Seleccione producto'),
                      items: _vendibles
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.codigo} · ${p.descripcion}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (p) => setState(() => _seleccion = p),
                      validator: (p) => p == null ? 'Seleccione un producto' : null,
                    ),
                    if (seleccion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                            'Valor: ${_dinero(seleccion.valor)}  ·  Disponible: ${_disponible(seleccion)}',
                            style: GoogleFonts.archivo(
                                color: AppColors.textoGris,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: decoracionFormulario('Cantidad'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 1) return 'Cantidad inválida';
                        final p = _seleccion;
                        if (p != null && n > _disponible(p)) {
                          return 'Máximo ${_disponible(p)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _agregar,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('Agregar',
                            style: GoogleFonts.archivo(
                                fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.azulEncabezado,
                          side: const BorderSide(
                              color: AppColors.azulEncabezado, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              if (_items.isEmpty)
                Text('Aún no has agregado productos.',
                    style: GoogleFonts.archivo(
                        color: AppColors.textoGris,
                        fontWeight: FontWeight.w700,
                        fontSize: 13))
              else
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${_items[i].cantidad} x ${_items[i].descripcion}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.archivo(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        Text(_dinero(_items[i].subtotal),
                            style: GoogleFonts.archivo(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close,
                              size: 18, color: AppColors.rojoCerrar),
                          onPressed: () => setState(() => _items.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Total: ${_dinero(_total)}',
                    style: GoogleFonts.archivo(
                        color: AppColors.azulTitulo,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar',
              style: GoogleFonts.archivo(
                  color: AppColors.azulTitulo, fontWeight: FontWeight.w800)),
        ),
        ElevatedButton(
          onPressed:
              _items.isEmpty ? null : () => Navigator.pop(context, List.of(_items)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.guardar,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child:
              Text('Vender', style: GoogleFonts.archivo(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
