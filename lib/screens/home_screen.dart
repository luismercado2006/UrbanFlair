import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/navegacion.dart';
import '../widgets/urban_flair_logo.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado: logo + cerrar sesión
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const UrbanFlairLogo(height: 52, sobreOscuro: false),
                  ElevatedButton(
                    onPressed: _cerrarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rojoCerrar,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cerrar Sesión',
                        style: GoogleFonts.archivo(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text('Bienvenido, $nombre 👋',
                                      style: GoogleFonts.archivo(
                                          color: AppColors.azulTitulo,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22)),
                                ),
                                const SizedBox(height: 14),
                                Text('Resumen General',
                                    style: GoogleFonts.archivo(
                                        color: AppColors.azulTitulo,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                    'Consulta Tus Datos E Indicadores\nClave De Un Vistazo.',
                                    style: GoogleFonts.archivo(fontSize: 12)),
                                const SizedBox(height: 16),
                                _TarjetaResumen(
                                    titulo: 'Productos',
                                    valor:
                                        '${_store.productos.length} Registros'),
                                _TarjetaResumen(
                                    titulo: 'Proveedores',
                                    valor:
                                        '${_store.proveedores.length} Activos'),
                                _TarjetaResumen(
                                    titulo: 'Ventas Del Mes',
                                    valor:
                                        '\$${_store.ventasMes.toStringAsFixed(0)} · ${_store.unidadesVendidasMes} Unidades'),
                                _TarjetaResumen(
                                    titulo: 'Stock Disponible',
                                    valor: '${_store.stockTotal} Unidades'),
                              ],
                            ),
                          ),
                          // Menú inferior azul
                          Expanded(
                            child: Container(
                              color: AppColors.azulEncabezado,
                              padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
                              // SingleChildScrollView sin desplazamiento:
                              // evita el aviso amarillo/negro de overflow.
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ItemMenu('Gráficos de ventas y más',
                                        () => _abrir(AppRoutes.graficos)),
                                    _ItemMenu(
                                        'Registrar Proveedor',
                                        () => _abrir(
                                            AppRoutes.registrarProveedor)),
                                    _ItemMenu(
                                        'Registrar Producto',
                                        () => _abrir(
                                            AppRoutes.registrarProducto)),
                                    _ItemMenu('Mis ventas',
                                        () => _abrir(AppRoutes.ventas)),
                                    _ItemMenu('Inventario',
                                        () => _abrir(AppRoutes.inventario)),
                                    _ItemMenu('Predicción',
                                        () => _abrir(AppRoutes.prediccion)),
                                    _ItemMenu('Perfil',
                                        () => _abrir(AppRoutes.perfil)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _TarjetaResumen extends StatelessWidget {
  final String titulo;
  final String valor;

  const _TarjetaResumen({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.tarjetaGris,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(4, 6)),
        ],
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: '$titulo - ',
                style: GoogleFonts.archivo(
                    color: AppColors.azulTitulo,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            TextSpan(
                text: valor,
                style: GoogleFonts.archivo(
                    color: AppColors.textoGris,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _ItemMenu(this.texto, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Text(texto,
            style: GoogleFonts.archivo(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
      ),
    );
  }
}