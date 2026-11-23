class Validators {
  static String? requerido(String? v, [String campo = 'Este campo']) =>
      (v == null || v.trim().isEmpty) ? '$campo es obligatorio' : null;

  static String? correo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese su correo';
    final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v.trim());
    return ok ? null : 'Correo no válido';
  }

  static String? contrasena(String? v) {
    if (v == null || v.isEmpty) return 'Ingrese su contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? entero(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obligatorio';
    final n = int.tryParse(v.trim());
    return (n == null || n < 0) ? 'Número inválido' : null;
  }

  static String? valor(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obligatorio';
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    return (n == null || n <= 0) ? 'Valor inválido' : null;
  }

  static String? telefono(String? v) {
    if (v == null || v.trim().isEmpty) return 'El teléfono es obligatorio';
    final digitos = v.replaceAll(RegExp(r'\D'), '');
    return (digitos.length < 7 || digitos.length > 13)
        ? 'Teléfono no válido'
        : null;
  }
}
