/// Modelo del formulario "Registrar Producto".
/// Tabla Supabase: productos
/// (codigop, categoria, descripcion, color, talla, marca, stock,
///  valor_produ, porcentaje_ganancia, proveedor_id, registrado_por)
class Producto {
  final String codigo; // columna codigop; la asigna un trigger en la BD
  final String categoria;
  final String descripcion;
  final String color;
  final String talla;
  final String marca;
  final int stock;
  final double valor; // precio de venta
  final String proveedor; // nombre completo (la BD guarda proveedor_id)

  const Producto({
    this.codigo = '',
    required this.categoria,
    required this.descripcion,
    required this.color,
    required this.talla,
    required this.marca,
    required this.stock,
    required this.valor,
    required this.proveedor,
  });

  /// Precio de venta = valor_produ * (1 + porcentaje_ganancia / 100)
  /// (igual que la función registrar_venta en Supabase).
  factory Producto.fromJson(Map<String, dynamic> j, {String proveedor = ''}) {
    final base = (j['valor_produ'] as num? ?? 0).toDouble();
    final ganancia = (j['porcentaje_ganancia'] as num? ?? 0).toDouble();
    final precio = double.parse((base * (1 + ganancia / 100)).toStringAsFixed(2));
    return Producto(
      codigo: (j['codigop'] ?? '') as String,
      categoria: (j['categoria'] ?? '') as String,
      descripcion: (j['descripcion'] ?? '') as String,
      color: (j['color'] ?? '') as String,
      talla: (j['talla'] ?? '') as String,
      marca: (j['marca'] ?? '') as String,
      stock: (j['stock'] as num? ?? 0).toInt(),
      valor: precio,
      proveedor: proveedor,
    );
  }

  Producto copyWith({String? codigo, int? stock}) => Producto(
        codigo: codigo ?? this.codigo,
        categoria: categoria,
        descripcion: descripcion,
        color: color,
        talla: talla,
        marca: marca,
        stock: stock ?? this.stock,
        valor: valor,
        proveedor: proveedor,
      );

  /// Body para insertar en Supabase.
  /// Un producto nuevo se guarda con 0 % de ganancia: valor_produ = valor.
  Map<String, dynamic> toInsertJson({int? proveedorId, String? registradoPor}) => {
        'categoria': categoria,
        'descripcion': descripcion,
        'color': color,
        'talla': talla,
        'marca': marca,
        'stock': stock,
        'valor_produ': valor,
        'porcentaje_ganancia': 0,
        'proveedor_id': proveedorId,
        'registrado_por': registradoPor,
      };
}