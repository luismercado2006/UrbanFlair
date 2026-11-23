import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';
import '../models/proveedor.dart';
import '../models/usuario.dart';
import '../models/venta.dart';

/// Almacén compartido por todas las pantallas.
/// Mantiene en memoria lo último que trajo de Supabase y expone los mismos
/// getters de antes, así las pantallas casi no cambian.
class AppStore {
  AppStore._();
  static final AppStore instance = AppStore._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Usuario de la sesión actual (null si no ha iniciado sesión).
  Usuario? usuario;

  // Listas FINAL: se vacían y rellenan (clear/addAll) para que las pantallas
  // que guardan la referencia sigan viendo los datos nuevos.
  final List<Producto> productos = [];
  final List<Proveedor> proveedores = [];
  final List<Venta> ventas = [];

  // ---------------------------------------------------------------- Auth

  Future<void> iniciarSesion(String correo, String password) async {
    await _db.auth.signInWithPassword(email: correo, password: password);
    await cargarUsuario();
    await cargarTodo();
  }

  /// Crea la cuenta. El perfil (tabla usuarios) lo crea un trigger en la BD
  /// a partir de nombre/apellido.
  Future<void> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
  }) async {
    await _db.auth.signUp(
      email: correo,
      password: password,
      data: {'nombre': nombre, 'apellido': apellido},
    );
    // Si Supabase deja la sesión abierta al registrarse, se cierra para que
    // el flujo siga siendo: registrarse -> iniciar sesión.
    if (_db.auth.currentSession != null) {
      await _db.auth.signOut();
    }
  }

  /// Google (web): redirige a Google y vuelve a la app; main.dart detecta la
  /// sesión al arrancar y entra al home.
  Future<void> iniciarConGoogle() async {
    await _db.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> cerrarSesion() async {
    await _db.auth.signOut();
    usuario = null;
    productos.clear();
    proveedores.clear();
    ventas.clear();
  }

  Future<void> cargarUsuario() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      usuario = null;
      return;
    }
    // perfil_actual() busca en tu tabla usuarios por correo y trae el rol
    // (roles / usuarios_roles) sin exponer la contraseña.
    final r = await _db.rpc('perfil_actual');
    if (r is List && r.isNotEmpty) {
      usuario = Usuario.fromJson(Map<String, dynamic>.from(r.first as Map));
    } else {
      usuario = Usuario(correo: user.email ?? '');
    }
  }

  // ------------------------------------------------------------ Lecturas

  Future<void> cargarTodo() => Future.wait([
        cargarProductos(), // también carga los proveedores
        cargarVentas(),
      ]);

  /// Trae primero los proveedores para poder mostrar el nombre del proveedor
  /// de cada producto (la BD solo guarda proveedor_id).
  Future<void> cargarProductos() async {
    await cargarProveedores();
    final nombres = {
      for (final p in proveedores)
        if (p.id != null) p.id!: p.nombreCompleto,
    };
    final filas = await _db.from('productos').select().order('id');
    productos
      ..clear()
      ..addAll(filas.map((f) => Producto.fromJson(f,
          proveedor: nombres[(f['proveedor_id'] as num?)?.toInt()] ?? '')));
  }

  Future<void> cargarProveedores() async {
    final filas = await _db.from('proveedores').select().order('nombre');
    proveedores
      ..clear()
      ..addAll(filas.map(Proveedor.fromJson));
  }

  /// Las políticas RLS hacen que cada usuario solo reciba SUS ventas.
  Future<void> cargarVentas() async {
    final cabeceras =
        await _db.from('ventas').select().order('fecha_venta', ascending: false);
    final detalles = await _db.from('detalle_venta').select();

    final porVenta = <int, List<Map<String, dynamic>>>{};
    for (final d in detalles) {
      porVenta.putIfAbsent((d['venta_id'] as num).toInt(), () => []).add(d);
    }
    ventas
      ..clear()
      ..addAll(cabeceras.map((c) =>
          Venta.fromJson(c, porVenta[(c['id'] as num).toInt()] ?? [])));
  }

  // ---------------------------------------------------------- Escrituras

  Future<void> agregarProducto(Producto p) async {
    // La BD guarda el id del proveedor; aquí se busca por su nombre.
    final prov = proveedores.where((x) => x.nombreCompleto == p.proveedor);
    final fila = await _db
        .from('productos')
        .insert(p.toInsertJson(
          proveedorId: prov.isEmpty ? null : prov.first.id,
          registradoPor: usuario?.correo,
        ))
        .select()
        .single();
    productos.add(Producto.fromJson(fila, proveedor: p.proveedor));
  }

  Future<void> agregarProveedor(Proveedor p) async {
    final fila =
        await _db.from('proveedores').insert(p.toJson()).select().single();
    proveedores.add(Proveedor.fromJson(fila));
  }

  /// Registra la venta en una sola transacción (función registrar_venta en
  /// Supabase): valida stock, descuenta y guarda venta + detalles.
  ///
  /// Devuelve la venta recién creada (para el comprobante con QR).
  Future<Venta> agregarVenta(List<ItemVenta> items) async {
    final antes = ventas.map((v) => v.codigo).toSet();
    await _db.rpc('registrar_venta',
        params: {'items': items.map((i) => i.toJson()).toList()});
    await Future.wait([cargarVentas(), cargarProductos()]);

    // La venta nueva es la que no estaba antes (la lista viene ordenada de
    // la más reciente a la más antigua).
    final nuevas = ventas.where((v) => !antes.contains(v.codigo));
    if (nuevas.isNotEmpty) return nuevas.first;

    // Respaldo: arma la venta con lo que se envió.
    return Venta(
      codigo: 'PENDIENTE',
      fecha: DateTime.now(),
      items: items,
    );
  }

  Venta? ventaPorCodigo(String codigo) {
    for (final v in ventas) {
      if (v.codigo == codigo) return v;
    }
    return null;
  }

  // ------------------------------------------------------------ Resumen

  List<Venta> get _ventasDelMes {
    final hoy = DateTime.now();
    return ventas
        .where((v) => v.fecha.year == hoy.year && v.fecha.month == hoy.month)
        .toList();
  }

  int get stockTotal => productos.fold(0, (s, p) => s + p.stock);
  double get ventasMes => _ventasDelMes.fold(0.0, (s, v) => s + v.total);
  int get unidadesVendidasMes =>
      _ventasDelMes.fold(0, (s, v) => s + v.unidades);
}

/// Convierte cualquier error en un mensaje legible para el usuario.
String mensajeError(Object e) {
  if (e is AuthException) return e.message;
  if (e is PostgrestException) return e.message;
  return 'No se pudo conectar. Revisa tu internet e inténtalo de nuevo.';
}