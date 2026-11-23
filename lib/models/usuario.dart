/// Usuario de la sesión actual (vista "Mi Perfil").
/// Tabla Supabase: usuarios (id, nombre, apellido, correo, rol)
class Usuario {
  final String nombre;
  final String apellido;
  final String correo;
  final String rol;

  const Usuario({
    this.nombre = '',
    this.apellido = '',
    required this.correo,
    this.rol = '',
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        nombre: (j['nombre'] ?? '') as String,
        apellido: (j['apellido'] ?? '') as String,
        correo: (j['correo'] ?? '') as String,
        rol: (j['rol'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'rol': rol,
      };
}