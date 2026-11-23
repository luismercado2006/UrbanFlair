import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_store.dart';
import '../models/venta.dart';
import '../theme/app_colors.dart';
import '../utils/formato.dart';

/// Comprobante de venta estilo Nequi: check animado, monto grande, detalle,
/// código QR y botón para compartir el comprobante como imagen.
class ComprobanteScreen extends StatefulWidget {
  final Venta venta;

  /// true = se acaba de vender (muestra la animación de éxito).
  final bool recienVendida;

  const ComprobanteScreen(
      {super.key, required this.venta, this.recienVendida = false});

  static Future<void> abrir(BuildContext context, Venta venta,
          {bool recienVendida = false}) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ComprobanteScreen(venta: venta, recienVendida: recienVendida),
      ));

  @override
  State<ComprobanteScreen> createState() => _ComprobanteScreenState();
}

class _ComprobanteScreenState extends State<ComprobanteScreen>
    with SingleTickerProviderStateMixin {
  final _capturaKey = GlobalKey();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _compartiendo = false;

  Venta get _v => widget.venta;

  @override
  void initState() {
    super.initState();
    if (widget.recienVendida) {
      _anim.forward();
    } else {
      _anim.value = 1;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Convierte el comprobante (lo que está dentro del RepaintBoundary) en PNG
  /// y lo comparte (WhatsApp, correo...). En web descarga la imagen.
  Future<void> _compartir() async {
    setState(() => _compartiendo = true);
    try {
      final boundary = _capturaKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final imagen = await boundary.toImage(pixelRatio: 3);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('No se pudo generar la imagen');

      final nombre = 'comprobante_${_v.codigo}.png';
      await SharePlus.instance.share(ShareParams(
        title: 'Comprobante ${_v.codigo}',
        subject: 'Comprobante de venta ${_v.codigo} - Urban Flair',
        text: kIsWeb
            ? null
            : 'Comprobante de venta ${_v.codigo} por ${dinero(_v.total)}',
        files: [
          XFile.fromData(bytes.buffer.asUint8List(),
              mimeType: 'image/png', name: nombre),
        ],
        fileNameOverrides: [nombre],
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo compartir el comprobante')));
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulEncabezado,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: RepaintBoundary(
                      key: _capturaKey,
                      child: _Recibo(venta: _v, anim: _anim),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _compartiendo ? null : _compartir,
                        icon: _compartiendo
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.share_outlined),
                        label: Text('Compartir',
                            style:
                                GoogleFonts.archivo(fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.azulEncabezado,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Listo',
                            style:
                                GoogleFonts.archivo(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El recibo en sí (es lo que se captura como imagen al compartir).
class _Recibo extends StatelessWidget {
  final Venta venta;
  final Animation<double> anim;

  const _Recibo({required this.venta, required this.anim});

  @override
  Widget build(BuildContext context) {
    final usuario = AppStore.instance.usuario;
    final vendedor = usuario == null
        ? ''
        : ('${usuario.nombre} ${usuario.apellido}'.trim().isEmpty
            ? usuario.correo
            : '${usuario.nombre} ${usuario.apellido}'.trim());

    TextStyle estilo(double size,
            {Color color = AppColors.azulTitulo,
            FontWeight peso = FontWeight.w800}) =>
        GoogleFonts.archivo(fontSize: size, color: color, fontWeight: peso);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF1DB954),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 14),
          Text('¡Venta exitosa!', style: estilo(22)),
          const SizedBox(height: 4),
          Text('Urban Flair', style: estilo(13, color: AppColors.textoGris)),
          const SizedBox(height: 16),
          FittedBox(
            child: Text(dinero(venta.total),
                style: estilo(38, color: AppColors.azulEncabezado)),
          ),
          const SizedBox(height: 18),
          _Fila('Código de venta', venta.codigo),
          _Fila('Fecha y hora', venta.fechaHoraTexto),
          if (vendedor.isNotEmpty) _Fila('Vendedor', vendedor),
          _Fila('Unidades', '${venta.unidades}'),
          const _Punteado(),
          for (final i in venta.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${i.cantidad} x ${i.descripcion}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(13, peso: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text(dinero(i.subtotal), style: estilo(13)),
                ],
              ),
            ),
          const _Punteado(),
          Row(
            children: [
              Expanded(child: Text('Total', style: estilo(16))),
              Text(dinero(venta.total), style: estilo(16)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.tarjetaGris),
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: venta.datosQr,
              size: 190,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.azulEncabezado),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.azulTitulo),
              errorStateBuilder: (_, _) => const SizedBox(
                width: 190,
                height: 190,
                child: Center(child: Text('No se pudo generar el QR')),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Escanea para ver los datos de la venta',
              style: estilo(12, color: AppColors.textoGris, peso: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Verificación: ${venta.codigoVerificacion}',
              style: estilo(12, color: AppColors.textoGris)),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Fila(this.titulo, this.valor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: GoogleFonts.archivo(
                    color: AppColors.textoGris,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(valor,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.archivo(
                      color: AppColors.azulTitulo,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ],
        ),
      );
}

/// Línea punteada tipo tirilla de recibo.
class _Punteado extends StatelessWidget {
  const _Punteado();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(builder: (_, c) {
          final n = (c.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                n,
                (_) => Container(
                    width: 4, height: 1.5, color: AppColors.tarjetaGris)),
          );
        }),
      );
}
