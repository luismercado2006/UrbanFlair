import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../models/producto.dart';
import '../theme/app_colors.dart';
import '../widgets/encabezado_azul.dart';

/// Inventario: una página por producto, con Anterior / Siguiente.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _productos = AppStore.instance.productos;
  int _pagina = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      await AppStore.instance.cargarProductos();
    } catch (_) {
      // Se muestra lo que haya en memoria.
    }
    if (!mounted) return;
    setState(() {
      if (_pagina >= _productos.length) _pagina = 0;
    });
  }

  bool get _hayAnterior => _pagina > 0;
  bool get _haySiguiente => _pagina < _productos.length - 1;

  List<MapEntry<String, String>> _filas(Producto? p) => [
        MapEntry('Código', p?.codigo ?? '—'),
        MapEntry('Categoría', p?.categoria ?? '—'),
        MapEntry('Descripción', p?.descripcion ?? '—'),
        MapEntry('Color', p?.color ?? '—'),
        MapEntry('Marca', p?.marca ?? '—'),
        MapEntry('Talla', p?.talla ?? '—'),
        MapEntry('Stock', p == null ? '—' : '${p.stock}'),
        MapEntry('Valor', p == null ? '—' : '\$${p.valor.toStringAsFixed(2)}'),
        MapEntry('Proveedor', p?.proveedor ?? '—'),
      ];

  @override
  Widget build(BuildContext context) {
    final producto = _productos.isEmpty ? null : _productos[_pagina];
    final filas = _filas(producto);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const EncabezadoAzul(),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 14),
              child: Text('Inventario De Productos',
                  style: GoogleFonts.archivo(
                      color: AppColors.azulTitulo,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(4, 6)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            for (final fila in filas)
                              _FilaInventario(
                                  etiqueta: fila.key, valor: fila.value),
                          ],
                        ),
                      ),
                    ),
                    if (producto == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text('Aún no hay productos registrados.',
                            style: GoogleFonts.archivo(
                                color: AppColors.textoGris,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ),
            // Paginación
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BotonPagina(
                    texto: 'Anterior',
                    onPressed:
                        _hayAnterior ? () => setState(() => _pagina--) : null,
                  ),
                  Text('Página ${_pagina + 1}',
                      style: GoogleFonts.archivo(
                          color: AppColors.textoGris,
                          fontWeight: FontWeight.w800)),
                  _BotonPagina(
                    texto: 'Siguiente',
                    onPressed:
                        _haySiguiente ? () => setState(() => _pagina++) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaInventario extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _FilaInventario({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Container(
            width: 112,
            color: AppColors.azulInventario,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.archivo(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
          Expanded(
            child: Container(
              color: AppColors.celdaInventario,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.archivo(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPagina extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;

  const _BotonPagina({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.azulEncabezado,
        side: BorderSide(
            color: onPressed == null ? AppColors.cancelar : AppColors.azulEncabezado,
            width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child:
          Text(texto, style: GoogleFonts.archivo(fontWeight: FontWeight.w800)),
    );
  }
}