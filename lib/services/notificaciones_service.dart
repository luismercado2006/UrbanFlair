import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/venta.dart';
import '../utils/formato.dart';

/// Notificaciones de "venta realizada" (estilo comprobante Nequi).
///
/// - Android / iOS / macOS / Windows / Linux: notificación del sistema.
/// - Web (Chrome): notificación del navegador (pide permiso la 1.ª vez).
/// Si el sistema no deja mostrarla (permiso negado, navegador sin soporte),
/// la pantalla de ventas igual muestra el aviso dentro de la app.
class NotificacionesService {
  NotificacionesService._();
  static final NotificacionesService instance = NotificacionesService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;
  int _siguienteId = 0;

  /// Se llama al tocar la notificación; recibe el código de la venta.
  void Function(String codigoVenta)? alTocar;

  static const _canal = AndroidNotificationDetails(
    'ventas',
    'Ventas realizadas',
    channelDescription: 'Comprobante de cada venta registrada',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF0B3A9B),
    ticker: 'Venta realizada',
  );

  Future<void> inicializar() async {
    if (_listo) return;
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(defaultActionName: 'Ver'),
          windows: WindowsInitializationSettings(
            appName: 'Urban Flair',
            appUserModelId: 'UrbanFlair.App',
            guid: '6f1c2b8e-4d3a-4b9e-9a51-2f7c3e8d1a40',
          ),
          web: WebInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (r) {
          final codigo = r.payload;
          if (codigo != null && codigo.isNotEmpty) alTocar?.call(codigo);
        },
      );
      _listo = ok ?? false;
    } catch (e) {
      debugPrint('Notificaciones no disponibles: $e');
      _listo = false;
    }
  }

  /// Pide permiso (Android 13+, iOS, macOS, navegador).
  /// En web debe llamarse tras un gesto del usuario (ej. botón "Vender").
  Future<bool> pedirPermiso() async {
    if (!_listo) return false;
    try {
      if (kIsWeb) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    WebFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>()
                  ?.requestNotificationsPermission() ??
              false;
        case TargetPlatform.iOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true) ??
              false;
        case TargetPlatform.macOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                      MacOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true) ??
              false;
        default:
          return true; // Windows / Linux no piden permiso.
      }
    } catch (_) {
      return false;
    }
  }

  /// Muestra "¡Venta exitosa! $ 120.000 · 3 productos". Devuelve true si
  /// el sistema la aceptó.
  Future<bool> notificarVenta(Venta venta) async {
    if (!_listo) return false;
    final unidades = venta.unidades;
    try {
      await _plugin.show(
        id: _siguienteId++,
        title: '¡Venta exitosa! ${dinero(venta.total)}',
        body: 'Venta ${venta.codigo} · $unidades '
            '${unidades == 1 ? 'producto' : 'productos'} · '
            '${venta.fechaHoraTexto}. Toca para ver el comprobante.',
        payload: venta.codigo,
        notificationDetails: const NotificationDetails(
          android: _canal,
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
      return false;
    }
  }
}
