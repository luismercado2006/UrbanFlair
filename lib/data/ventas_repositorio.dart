import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/datos_graficas.dart';

/// Entrega los datos de las gráficas desde las vistas de Supabase
/// (v_ventas_por_mes y v_ventas_por_categoria, definidas en supabase_schema.sql).
class VentasRepositorio {
  SupabaseClient get _db => Supabase.instance.client;

  static const _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  Future<List<SerieVentas>> ventasPorMes() async {
    final filas = await _db.from('v_ventas_por_mes').select().order('mes_fecha');

    String claveDe(DateTime fecha) =>
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';

    // Unidades por categoría y mes (clave aaaa-mm), y el rango de meses.
    DateTime? primero;
    DateTime? ultimo;
    final porCategoria = <String, Map<String, double>>{};
    for (final f in filas) {
      final fecha = DateTime.parse(f['mes_fecha'] as String);
      final mes = DateTime(fecha.year, fecha.month);
      if (primero == null || mes.isBefore(primero)) primero = mes;
      if (ultimo == null || mes.isAfter(ultimo)) ultimo = mes;
      final cat = f['categoria'] as String;
      porCategoria.putIfAbsent(cat, () => {})[claveDe(mes)] =
          (f['unidades'] as num).toDouble();
    }

    // Todos los meses entre el primero y el último, aunque no tengan ventas,
    // para que la línea no una meses lejanos como si fueran seguidos.
    final ordenados = <String>[];
    if (primero != null && ultimo != null) {
      for (var m = primero;
          !m.isAfter(ultimo);
          m = DateTime(m.year, m.month + 1)) {
        ordenados.add(claveDe(m));
      }
    }

    // Si el rango pasa de 12 meses, se agrega el año para no repetir etiquetas
    // (el eje de categorías juntaría dos "Jun" en el mismo punto).
    final conAnio = ordenados.length > 12;
    String etiqueta(String clave) {
      final mes = _meses[int.parse(clave.substring(5)) - 1];
      return conAnio ? '$mes ${clave.substring(2, 4)}' : mes;
    }

    return porCategoria.entries
        .map((e) => SerieVentas(
              e.key,
              [
                for (final m in ordenados)
                  PuntoVenta(etiqueta(m), e.value[m] ?? 0),
              ],
            ))
        .toList();
  }

  Future<List<VentaCategoria>> ventasPorCategoria() async {
    final filas = await _db.from('v_ventas_por_categoria').select();
    return filas
        .map((f) => VentaCategoria(
            f['categoria'] as String, (f['unidades'] as num).toDouble()))
        .toList();
  }
}