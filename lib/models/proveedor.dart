/// Modelo del formulario "Registrar Proveedor".
/// Tabla Supabase: proveedores (id, nombre, apellido, email, telefono, direccion)
class Proveedor {
  final int? id; // lo asigna la base de datos
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String direccion;

  const Proveedor({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.direccion,
  });

  factory Proveedor.fromJson(Map<String, dynamic> j) => Proveedor(
        id: (j['id'] as num?)?.toInt(),
        nombre: (j['nombre'] ?? '') as String,
        apellido: (j['apellido'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        telefono: (j['telefono'] ?? '') as String,
        direccion: (j['direccion'] ?? '') as String,
      );

  String get nombreCompleto => '$nombre $apellido'.trim();

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'telefono': telefono,
        'direccion': direccion,
      };
}