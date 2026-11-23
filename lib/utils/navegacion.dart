import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../routes/app_routes.dart';

/// Regresa al Home desde cualquier vista interna
/// (flecha superior derecha, Cancelar y Guardar).
void volverAlHome(BuildContext context) {
  Navigator.popUntil(context, ModalRoute.withName(AppRoutes.home));
}

/// Cierra la sesión en Supabase y lleva al Login
/// (Home y Mi Perfil usan esta función).
Future<void> cerrarSesion(BuildContext context) async {
  try {
    await AppStore.instance.cerrarSesion();
  } catch (_) {
    // Aunque falle la red, se limpia el estado local y se sale.
    AppStore.instance.usuario = null;
  }
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
}