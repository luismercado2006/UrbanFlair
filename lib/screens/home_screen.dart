import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/navegacion.dart';
import '../widgets/logo_recortado.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = AppStore.instance;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  /// Trae de Supabase los datos del resumen y repinta.
  Future<void> _recargar() async {
    try {
      await _store.cargarTodo();
    } catch (_) {
      // Si falla la red se muestra lo último que había en memoria.
    }
    if (mounted) setState(() {});
  }

  void _cerrarSesion() => cerrarSesion(context);

  /// Abre una vista y, al volver (flecha, Cancelar o Guardar),
  /// refresca el resumen del Home con datos reales.
  Future<void> _abrir(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    if (mounted) {
      setState(() {});
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreUsuario = _store.usuario?.nombre ?? '';
    final nombre = nombreUsuario.isEmpty ? 'Usuario' : nombreUsuario;

    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = ancho < 600;
    final cuatroColumnas = ancho >= 900;
    final margenX = compacto ? 16.0 : 24.0;
    final separacion = compacto ? 12.0 : 16.0;
    final paddingFila = ancho >= 800 ? 20.0 : 16.0;

    final indicadores = <Widget>[
      _TarjetaIndicador(
          etiqueta: 'Productos',
          valor: '${_store.productos.length}',
          detalle: 'registros',
          icono: Icons.inventory_2_outlined,
          valorGrande: ancho >= 420),
      _TarjetaIndicador(
          etiqueta: 'Proveedores',
          valor: '${_store.proveedores.length}',
          detalle: 'activos',
          icono: Icons.people_outline,
          valorGrande: ancho >= 420),
      _TarjetaIndicador(
          etiqueta: 'Ventas del mes',
          valor: '\$${_conMiles(_store.ventasMes)}',
          detalle: '${_store.unidadesVendidasMes} unidades',
          icono: Icons.receipt_long_outlined,
          valorGrande: ancho >= 420),
      _TarjetaIndicador(
          etiqueta: 'Stock disponible',
          valor: _conMiles(_store.stockTotal),
          detalle: 'unidades',
          icono: Icons.warehouse_outlined,
          valorGrande: ancho >= 420),
    ];

    final panelVentas = _PanelModulos(
      titulo: 'Ventas y análisis',
      padding: paddingFila,
      filas: [
        _FilaModulo(
            icono: Icons.receipt_long_outlined,
            titulo: 'Mis ventas',
            descripcion: 'Consulta el historial de tus ventas.',
            padding: paddingFila,
            onTap: () => _abrir(AppRoutes.ventas)),
        _FilaModulo(
            icono: Icons.bar_chart_outlined,
            titulo: 'Gráficos de ventas y más',
            descripcion: 'Visualiza los indicadores de ventas.',
            padding: paddingFila,
            onTap: () => _abrir(AppRoutes.graficos)),
        _FilaModulo(
            icono: Icons.trending_up,
            titulo: 'Predicción',
            descripcion: 'Consulta la proyección de tus ventas.',
            padding: paddingFila,
            onTap: () => _abrir(AppRoutes.prediccion)),
      ],
    );

    final panelCatalogo = _PanelModulos(
      titulo: 'Catálogo',
      padding: paddingFila,
      filas: [
        _FilaModulo(
            icono: Icons.add_box_outlined,
            titulo: 'Registrar producto',
            descripcion: 'Añade productos a tu catálogo.',
            padding: paddingFila,
            onTap: () => _abrir(AppRoutes.registrarProducto)),
        _FilaModulo(
            icono: Icons.warehouse_outlined,
            titulo: 'Inventario',
            descripcion: 'Consulta tus productos y existencias.',
            padding: paddingFila,
            onTap: () => _abrir(AppRoutes.inventario)),
        _FilaModulo(
            icono: Icons.person_add_alt_outlined,
            titulo: 'Registrar proveedor',
            descripcion: 'Añade un proveedor a tu registro.',
            padding: paddingFila,
            onTap: () => _abrir(AppRoutes.registrarProveedor)),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.campoClaro,
      body: Column(
        children: [
          // Navbar fijo: logo + Mi perfil + Cerrar sesión
          Container(
            color: AppColors.azulEncabezado,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: margenX),
                    child: SizedBox(
                      height: compacto ? 56 : 64,
                      child: Row(
                        children: [
                          LogoRecortado(alto: compacto ? 36 : 44),
                          const Spacer(),
                          _BotonNavbar(
                            icono: Icons.person_outline,
                            texto: 'Mi perfil',
                            compacto: compacto,
                            colorHover: Colors.white,
                            onPressed: () => _abrir(AppRoutes.perfil),
                          ),
                          SizedBox(width: compacto ? 4 : 12),
                          _BotonNavbar(
                            icono: Icons.logout,
                            texto: 'Cerrar sesión',
                            compacto: compacto,
                            colorHover: AppColors.rojoCerrar,
                            onPressed: _cerrarSesion,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Contenido con scroll
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(margenX, 32, margenX, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Bienvenido, $nombre',
                              style: GoogleFonts.archivoBlack(
                                  color: AppColors.azulTitulo,
                                  fontSize: compacto ? 22 : 28,
                                  height: 1.25,
                                  letterSpacing: -0.6)),
                          const SizedBox(height: 8),
                          Text(
                              'Consulta tus datos e indicadores clave de un vistazo.',
                              style: GoogleFonts.archivo(
                                  color: _textoSecundario,
                                  fontSize: 14,
                                  height: 24 / 14)),
                          const SizedBox(height: 24),
                          if (cuatroColumnas)
                            _filaIgual(indicadores, separacion)
                          else ...[
                            _filaIgual(indicadores.sublist(0, 2), separacion),
                            SizedBox(height: separacion),
                            _filaIgual(indicadores.sublist(2), separacion),
                          ],
                          const SizedBox(height: 24),
                          if (cuatroColumnas)
                            _filaIgual([panelVentas, panelCatalogo], 24)
                          else ...[
                            panelVentas,
                            const SizedBox(height: 24),
                            panelCatalogo,
                          ],
                          const SizedBox(height: 48),
                          Text(
                              '© ${DateTime.now().year} Urban Flair. Todos los derechos reservados.',
                              style: GoogleFonts.archivo(
                                  color: _textoSecundario,
                                  fontSize: 12,
                                  height: 20 / 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Presentación del Home =====================

/// Gris del texto secundario (azulTitulo al 60%).
final Color _textoSecundario = AppColors.azulTitulo.withValues(alpha: 0.6);

/// Formato solo visual: redondea sin decimales y agrega puntos de miles.
/// 3152612.4 -> 3.152.612
String _conMiles(num valor) => valor.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

/// Fila de hijos con el mismo ancho y una separación fija.
Widget _filaIgual(List<Widget> hijos, double separacion) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < hijos.length; i++) ...[
          if (i > 0) SizedBox(width: separacion),
          Expanded(child: hijos[i]),
        ],
      ],
    );

/// Superficie blanca con borde tarjetaGris, esquinas de 12 y sombra mínima.
Widget _superficie(Widget hijo) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AppColors.azulTitulo.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.tarjetaGris),
        ),
        child: hijo,
      ),
    );

class _BotonNavbar extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool compacto;
  final Color colorHover;
  final VoidCallback onPressed;

  const _BotonNavbar({
    required this.icono,
    required this.texto,
    required this.compacto,
    required this.colorHover,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final boton = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: compacto ? const Size(40, 40) : const Size(0, 36),
        fixedSize: compacto ? const Size(40, 40) : null,
        padding: EdgeInsets.symmetric(horizontal: compacto ? 0 : 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).copyWith(
        foregroundColor: WidgetStateProperty.resolveWith((estados) =>
            estados.contains(WidgetState.hovered)
                ? colorHover
                : Colors.white.withValues(alpha: 0.85)),
        overlayColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.12);
          }
          if (estados.contains(WidgetState.hovered) ||
              estados.contains(WidgetState.focused)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          return null;
        }),
      ),
      child: compacto
          ? Icon(icono, size: 18)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 18),
                const SizedBox(width: 8),
                Text(texto,
                    style: GoogleFonts.archivo(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
    );
    return compacto ? Tooltip(message: texto, child: boton) : boton;
  }
}

class _TarjetaIndicador extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String detalle;
  final IconData icono;
  final bool valorGrande;

  const _TarjetaIndicador({
    required this.etiqueta,
    required this.valor,
    required this.detalle,
    required this.icono,
    required this.valorGrande,
  });

  @override
  Widget build(BuildContext context) {
    final tamValor = valorGrande ? 30.0 : 26.0;
    return _superficie(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.archivo(
                          color: _textoSecundario,
                          fontSize: 13,
                          height: 20 / 13,
                          letterSpacing: -0.3)),
                ),
                const SizedBox(width: 4),
                Icon(icono, size: 18, color: AppColors.azulBoton),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor,
                  maxLines: 1,
                  style: GoogleFonts.archivo(
                      color: AppColors.azulTitulo,
                      fontSize: tamValor,
                      fontWeight: FontWeight.w700,
                      height: 36 / tamValor,
                      letterSpacing: -1,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            const SizedBox(height: 4),
            Text(detalle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.archivo(
                    color: _textoSecundario, fontSize: 13, height: 20 / 13)),
          ],
        ),
      ),
    );
  }
}

class _PanelModulos extends StatelessWidget {
  final String titulo;
  final double padding;
  final List<Widget> filas;

  const _PanelModulos({
    required this.titulo,
    required this.padding,
    required this.filas,
  });

  @override
  Widget build(BuildContext context) {
    const linea = Divider(height: 1, thickness: 1, color: AppColors.tarjetaGris);
    return _superficie(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
            child: Text(titulo,
                style: GoogleFonts.archivo(
                    color: AppColors.azulTitulo,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
          for (final fila in filas) ...[linea, fila],
        ],
      ),
    );
  }
}

class _FilaModulo extends StatefulWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final double padding;
  final VoidCallback onTap;

  const _FilaModulo({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.padding,
    required this.onTap,
  });

  @override
  State<_FilaModulo> createState() => _FilaModuloState();
}

class _FilaModuloState extends State<_FilaModulo> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (h) => setState(() => _hover = h),
      hoverColor: AppColors.campoClaro,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: widget.padding, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.azulBoton.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(widget.icono, size: 20, color: AppColors.azulBoton),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.titulo,
                        style: GoogleFonts.archivo(
                            color: AppColors.azulTitulo,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 20 / 15)),
                    Text(widget.descripcion,
                        style: GoogleFonts.archivo(
                            color: _textoSecundario,
                            fontSize: 13,
                            height: 20 / 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  size: 20,
                  color: _hover ? AppColors.azulBoton : _textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}