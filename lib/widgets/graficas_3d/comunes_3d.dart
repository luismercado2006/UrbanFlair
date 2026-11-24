import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Colores: las categorías usan el mismo mapa de la vista clásica
// (ColoresGraficas); el resto, AppColors y sus variaciones.
// ---------------------------------------------------------------------------

class Colores3D {
  Colores3D._();

  /// Resaltado al tocar un elemento.
  static const resaltado = AppColors.celesteLink;

  /// Mismo color con otra luminosidad (más claro: delta > 0).
  static Color tono(Color c, double delta) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + delta).clamp(0.08, 0.85))
        .toColor();
  }

  /// Color de una categoría (el mismo mapa de la vista clásica).
  static Color deCategoria(Map<String, Color> colores, String categoria) =>
      colores[categoria] ?? AppColors.textoGris;

  /// Azules de la app para capas en el tiempo: más claro = más antiguo.
  static Color capa(int i, int n) {
    final t = n <= 1 ? 1.0 : i / (n - 1);
    return Color.lerp(
      tono(AppColors.bordeAuth, 0.22),
      AppColors.azulTitulo,
      t,
    )!;
  }
}

/// Estilo de los selectores en línea (SegmentedButton) con colores de la app.
ButtonStyle estiloSegmentos3D(BuildContext context) =>
    SegmentedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.azulTitulo,
      selectedBackgroundColor: AppColors.azulEncabezado,
      selectedForegroundColor: Colors.white,
      side: const BorderSide(color: AppColors.azulEncabezado),
      textStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );

// ---------------------------------------------------------------------------
// Formato
// ---------------------------------------------------------------------------

String unidades(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String porcentaje(double parte, double total) =>
    total <= 0 ? '0%' : '${(parte / total * 100).toStringAsFixed(1)}%';

String recortar(String t, int max) =>
    t.length <= max ? t : '${t.substring(0, max - 1)}…';

// ---------------------------------------------------------------------------
// Tarjeta, título, estados
// ---------------------------------------------------------------------------

/// Misma tarjeta que la vista clásica (marco gris claro, fondo blanco,
/// bordes redondeados y sombra), pero con alto según su contenido.
class Tarjeta3D extends StatelessWidget {
  const Tarjeta3D({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.campoClaro,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(4, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

class Titulo3D extends StatelessWidget {
  const Titulo3D(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: AppColors.azulTitulo, fontWeight: FontWeight.w700),
    );
  }
}

/// Cargando / error / sin datos, con los mismos textos de la vista clásica.
class Estado3D extends StatelessWidget {
  const Estado3D.cargando({super.key}) : texto = null;
  const Estado3D.error({super.key}) : texto = 'No se pudieron cargar los datos';
  const Estado3D.vacio({super.key}) : texto = 'Aún no hay ventas para graficar';

  final String? texto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: texto == null
            ? const CircularProgressIndicator(color: AppColors.azulEncabezado)
            : Text(texto!),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leyenda tocable (mismo formato que la de "Ventas por mes": muestra de color
// tipo línea con punto + nombre; al ocultar, la muestra y el texto se apagan)
// ---------------------------------------------------------------------------

class ElementoLeyenda {
  const ElementoLeyenda(
    this.texto,
    this.color, {
    required this.activo,
    this.habilitado = true,
  });

  final String texto;
  final Color color;
  final bool activo;

  /// false = se muestra apagado y no se puede tocar (p. ej. mes sin ventas).
  final bool habilitado;
}

class Leyenda3D extends StatelessWidget {
  const Leyenda3D({
    super.key,
    required this.elementos,
    required this.alTocar,
    required this.ayuda,
    this.titulo,
  });

  final List<ElementoLeyenda> elementos;
  final ValueChanged<int> alTocar;
  final String ayuda;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (titulo != null)
          Text(
            titulo!,
            textAlign: TextAlign.center,
            style: tema.labelMedium?.copyWith(
              color: AppColors.azulTitulo,
              fontWeight: FontWeight.w700,
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 0,
          children: [
            for (var i = 0; i < elementos.length; i++)
              _ItemLeyenda(
                elemento: elementos[i],
                estilo: tema.bodySmall,
                alTocar: () => alTocar(i),
              ),
          ],
        ),
        Text(
          ayuda,
          textAlign: TextAlign.center,
          style: tema.labelSmall?.copyWith(color: AppColors.textoGris),
        ),
      ],
    );
  }
}

class _ItemLeyenda extends StatelessWidget {
  const _ItemLeyenda({
    required this.elemento,
    required this.estilo,
    required this.alTocar,
  });

  final ElementoLeyenda elemento;
  final TextStyle? estilo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final encendido = elemento.activo && elemento.habilitado;
    final colorMuestra = encendido ? elemento.color : AppColors.cancelar;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: elemento.habilitado ? alTocar : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Muestra de color: línea con punto, como en la vista clásica.
            SizedBox(
              width: 18,
              height: 10,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(height: 2, color: colorMuestra),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorMuestra,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              elemento.texto,
              style: estilo?.copyWith(
                color: encendido ? AppColors.azulTitulo : AppColors.textoGris,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel fijo con el valor exacto de lo tocado
// ---------------------------------------------------------------------------

class Panel3D extends StatelessWidget {
  const Panel3D({super.key, this.titulo, this.filas = const []});

  /// null = no hay nada seleccionado.
  final String? titulo;
  final List<(String, String)> filas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Container(
      height: 92,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.campoClaro,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: titulo == null ? AppColors.tarjetaGris : Colores3D.resaltado,
          width: titulo == null ? 1 : 1.6,
        ),
      ),
      child: titulo == null
          ? Center(
              child: Text(
                'Toca un elemento de la gráfica para ver su valor exacto',
                textAlign: TextAlign.center,
                style: tema.bodySmall?.copyWith(color: AppColors.textoGris),
              ),
            )
          // Alto fijo: si el texto no cabe (letra muy grande), se recorta
          // en vez de desbordar.
          : SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.titleSmall?.copyWith(
                      color: AppColors.azulTitulo,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 14,
                    runSpacing: 2,
                    children: [
                      for (final (etiqueta, valor) in filas)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$etiqueta: ',
                                style: const TextStyle(
                                  color: AppColors.textoGris,
                                ),
                              ),
                              TextSpan(
                                text: valor,
                                style: const TextStyle(
                                  color: AppColors.azulEncabezado,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          style: tema.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
