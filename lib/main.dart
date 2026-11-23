import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/app_store.dart';
import 'routes/app_routes.dart';
import 'screens/comprobante_screen.dart';
import 'services/notificaciones_service.dart';
import 'theme/app_colors.dart';

/// Permite navegar desde fuera de un widget (al tocar una notificación).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Si ya hay sesión guardada (o volvió de Google en web), entra directo al home.
  var rutaInicial = AppRoutes.login;
  if (Supabase.instance.client.auth.currentSession != null) {
    try {
      await AppStore.instance.cargarUsuario();
      await AppStore.instance.cargarTodo();
      rutaInicial = AppRoutes.home;
    } catch (_) {
      // Si falla la carga, se queda en el login.
    }
  }

  // Notificaciones de venta: al tocar una, abre su comprobante con QR.
  final notificaciones = NotificacionesService.instance;
  notificaciones.alTocar = (codigo) async {
    final store = AppStore.instance;
    var venta = store.ventaPorCodigo(codigo);
    if (venta == null) {
      try {
        await store.cargarVentas();
        venta = store.ventaPorCodigo(codigo);
      } catch (_) {}
    }
    final ctx = navigatorKey.currentContext;
    if (venta != null && ctx != null && ctx.mounted) {
      ComprobanteScreen.abrir(ctx, venta);
    }
  };
  await notificaciones.inicializar();

  runApp(UrbanFlairApp(rutaInicial: rutaInicial));
}

class UrbanFlairApp extends StatelessWidget {
  final String rutaInicial;

  const UrbanFlairApp({super.key, this.rutaInicial = AppRoutes.login});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Flair',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.azulBoton),
        textTheme: GoogleFonts.archivoTextTheme(),
      ),
      initialRoute: rutaInicial,
      routes: AppRoutes.routes,
    );
  }
}