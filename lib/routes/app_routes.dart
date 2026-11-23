import 'package:flutter/widgets.dart';

import '../screens/charts_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/login_screen.dart';
import '../screens/prediction_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_product_screen.dart';
import '../screens/register_provider_screen.dart';
import '../screens/register_screen.dart';
import '../screens/sales_screen.dart';

/// Mapeo central de rutas de la app.
class AppRoutes {
  static const login = '/login';
  static const registro = '/registro';
  static const home = '/home';
  static const registrarProducto = '/registrar-producto';
  static const registrarProveedor = '/registrar-proveedor';
  static const inventario = '/inventario';
  static const prediccion = '/prediccion';
  static const ventas = '/mis-ventas';
  static const graficos = '/graficos';
  static const perfil = '/perfil';

  static final Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    registro: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
    registrarProducto: (_) => const RegisterProductScreen(),
    registrarProveedor: (_) => const RegisterProviderScreen(),
    inventario: (_) => const InventoryScreen(),
    prediccion: (_) => const PredictionScreen(),
    ventas: (_) => const SalesScreen(),
    graficos: (_) => const ChartsScreen(),
    perfil: (_) => const ProfileScreen(),
  };
}