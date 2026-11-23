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

    // Meses ordenados que aparecen en los datos (clave aaaa-mm).
    final meses = <String>{};
    final porCategoria = <String, Map<String, double>>{};
    for (final f in filas) {
      final fecha = DateTime.parse(f['mes_fecha'] as String);
      final clave =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      meses.add(clave);
      final cat = f['categoria'] as String;
      porCategoria.putIfAbsent(cat, () => {})[clave] =
          (f['unidades'] as num).toDouble();
    }
    final ordenados = meses.toList()..sort();

    String etiqueta(String clave) => _meses[int.parse(clave.substring(5)) - 1];

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