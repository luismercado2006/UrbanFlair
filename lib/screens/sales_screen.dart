import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../models/venta.dart';
import '../services/notificaciones_service.dart';
import '../theme/app_colors.dart';
import '../widgets/encabezado_azul.dart';
import '../widgets/nueva_venta_dialog.dart';
import 'comprobante_screen.dart';

String _dinero(double v) => '\$${v.toStringAsFixed(2)}';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _store = AppStore.instance;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      await Future.wait([_store.cargarVentas(), _store.cargarProductos()]);
    } catch (_) {
      // Se muestra lo que haya en memoria.
    }
    if (mounted) setState(() {});
  }

  Future<void> _nuevaVenta() async {
    // El diálogo necesita el stock actualizado.
    try {
      await _store.cargarProductos();
    } catch (_) {}
    if (!mounted) return;

    final items = await NuevaVentaDialog.mostrar(context);
    if (items == null || items.isEmpty || !mounted) return;

    // Se pide aquí porque viene de un gesto del usuario (requisito en web).
    final notificaciones = NotificacionesService.instance;
    final permiso = notificaciones.pedirPermiso();

    try {
      final venta = await _store.agregarVenta(items);
      if (!mounted) return;
      setState(() {});

      // Notificación tipo comprobante + pantalla con el QR.
      if (await permiso) await notificaciones.notificarVenta(venta);
      if (!mounted) return;
      await ComprobanteScreen.abrir(context, venta, recienVendida: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ventas = _store.ventas;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const EncabezadoAzul(),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 10),
              child: Text('Mis Ventas',
                  style: GoogleFonts.archivo(
                      color: AppColors.azulTitulo,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _nuevaVenta,
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text('Nueva Venta',
                    style: GoogleFonts.archivo(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulEncabezado,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ventas.isEmpty
                  ? Center(
                      child: Text('Aún no hay ventas registradas.',
                          style: GoogleFonts.archivo(
                              color: AppColors.textoGris,
                              fontWeight: FontWeight.w700)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: ventas.length,
                      itemBuilder: (_, i) => _TarjetaVenta(venta: ventas[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaVenta extends StatelessWidget {
  final Venta venta;

  const _TarjetaVenta({required this.venta});

  Widget _columna(String titulo, String valor) => Column(
        children: [
          Text(titulo,
              style: GoogleFonts.archivo(
                  color: AppColors.azulTitulo,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 10),
          Text(valor,
              style: GoogleFonts.archivo(
                  color: AppColors.textoGris,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ],
      );

  void _verDetalles(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Venta ${venta.codigo}',
            style: GoogleFonts.archivo(
                color: AppColors.azulTitulo, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${venta.fechaTexto}'),
              const SizedBox(height: 10),
              if (venta.items.isEmpty)
                const Text('Sin detalle de productos.')
              else
                for (final item in venta.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                                '${item.cantidad} x ${item.descripcion}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        Text(_dinero(item.subtotal)),
                      ],
                    ),
                  ),
              const Divider(height: 20),
              Text('Total: ${_dinero(venta.total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ComprobanteScreen.abrir(context, venta);
            },
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Comprobante QR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: AppColors.campoClaro,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(4, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _columna('Código', venta.codigo),
              _columna('Fecha', venta.fechaTexto),
              _columna('Total', _dinero(venta.total)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 190,
            height: 42,
            child: ElevatedButton(
              onPressed: () => _verDetalles(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.guardar,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Ver Detalles',
                  style: GoogleFonts.archivo(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}