/// Un punto de la gráfica de líneas (mes + unidades vendidas).
class PuntoVenta {
  final String mes;
  final double unidades;
  const PuntoVenta(this.mes, this.unidades);
}

/// Una línea de la gráfica (una categoría con sus puntos por mes).
class SerieVentas {
  final String nombre;
  final List<PuntoVenta> puntos;
  const SerieVentas(this.nombre, this.puntos);
}

/// Una barra de la gráfica radial (total por categoría).
class VentaCategoria {
  final String categoria;
  final double unidades;
  const VentaCategoria(this.categoria, this.unidades);
}
