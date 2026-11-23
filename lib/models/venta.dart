/// Línea de una venta (un producto con su cantidad).
/// Tabla Supabase: detalle_venta
/// (id_producto, nombre_producto, cantidad, precio_unitario, subtotal, ...)
class ItemVenta {
  final String codigoProducto;
  final String descripcion;
  final int cantidad;
  final double valorUnitario;

  const ItemVenta({
    required this.codigoProducto,
    required this.descripcion,
    required this.cantidad,
    required this.valorUnitario,
  });

  factory ItemVenta.fromJson(Map<String, dynamic> j) => ItemVenta(
        codigoProducto: (j['id_producto'] ?? '') as String,
        descripcion: (j['nombre_producto'] ?? '') as String,
        cantidad: (j['cantidad'] as num? ?? 0).toInt(),
        valorUnitario: (j['precio_unitario'] as num? ?? 0).toDouble(),
      );

  double get subtotal => cantidad * valorUnitario;

  /// Lo que recibe la función registrar_venta de Supabase.
  /// (El nombre y el precio los toma la BD del producto, por seguridad.)
  Map<String, dynamic> toJson() => {
        'codigo_producto': codigoProducto,
        'cantidad': cantidad,
      };
}

/// Venta registrada (vista "Mis Ventas").
/// Tabla Supabase: ventas (codigo_venta, fecha_venta, total) + detalle_venta
class Venta {
  final String codigo;
  final DateTime fecha;
  final List<ItemVenta> items;
  final double? totalRegistrado; // columna total de la BD

  Venta({
    required this.codigo,
    required this.fecha,
    this.items = const [],
    this.totalRegistrado,
  });

  factory Venta.fromJson(
    Map<String, dynamic> j,
    List<Map<String, dynamic>> detalles,
  ) =>
      Venta(
        codigo: (j['codigo_venta'] ?? '') as String,
        fecha: j['fecha_venta'] == null
            ? DateTime.now()
            : DateTime.parse(j['fecha_venta'] as String),
        items: detalles.map(ItemVenta.fromJson).toList(),
        totalRegistrado: (j['total'] as num?)?.toDouble(),
      );

  /// Si hay detalle, suma sus líneas; si no, usa el total guardado.
  double get total => items.isEmpty
      ? (totalRegistrado ?? 0)
      : items.fold(0.0, (s, i) => s + i.subtotal);
  int get unidades => items.fold(0, (s, i) => s + i.cantidad);

  /// Fecha como dd/MM/aa (igual que el mockup).
  String get fechaTexto {
    String d(int n) => n.toString().padLeft(2, '0');
    return '${d(fecha.day)}/${d(fecha.month)}/${d(fecha.year % 100)}';
  }

  /// Fecha y hora local: dd/MM/aaaa hh:mm
  String get fechaHoraTexto {
    final f = fecha.toLocal();
    String d(int n) => n.toString().padLeft(2, '0');
    return '${d(f.day)}/${d(f.month)}/${f.year} ${d(f.hour)}:${d(f.minute)}';
  }

  /// Código corto de verificación (hash FNV-1a de código|fecha|total).
  /// Permite notar si alguien alteró a mano el texto del QR. No es una firma
  /// criptográfica: para eso habría que firmar en el servidor (Supabase).
  String get codigoVerificacion {
    final base =
        '$codigo|${fecha.toUtc().toIso8601String()}|${total.toStringAsFixed(2)}';
    var h = 0x811c9dc5;
    for (final c in base.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).toUpperCase().padLeft(8, '0');
  }

  /// Texto que va dentro del QR. Es legible con cualquier lector de QR
  /// (cámara del celular) sin necesitar la app.
  String get datosQr {
    final lineas = [
      'URBAN FLAIR - Comprobante de venta',
      'Codigo: $codigo',
      'Fecha: $fechaHoraTexto',
      // Máximo 8 líneas para que el QR siga siendo fácil de escanear.
      for (final i in items.take(8))
        '${i.cantidad} x ${i.descripcion} = ${i.subtotal.toStringAsFixed(2)}',
      if (items.length > 8) '... y ${items.length - 8} productos mas',
      'Unidades: $unidades',
      'Total: ${total.toStringAsFixed(2)}',
      'Verificacion: $codigoVerificacion',
    ];
    return lineas.join('\n');
  }
}