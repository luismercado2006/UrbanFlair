/// Dinero con separador de miles: 1234.5 -> $1,234.50
String dinero(double v) {
  final partes = v.toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '\$$entero.${partes[1]}';
}

