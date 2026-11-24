import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Motor 3D mínimo en Flutter puro:
/// - proyección en perspectiva (cámara que gira en Y y en X, con zoom),
/// - ordenamiento por profundidad (algoritmo del pintor),
/// - sombreado por cara según su orientación frente a una luz fija,
/// - descarte de caras traseras en sólidos cerrados,
/// - detección de toques sobre lo proyectado.

/// Vector / punto en 3D.
class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double k) => Vec3(x * k, y * k, z * k);

  double punto(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cruz(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get largo => math.sqrt(punto(this));

  Vec3 normalizado() {
    final l = largo;
    return l == 0 ? this : this * (1 / l);
  }

  static Vec3 promedio(List<Vec3> ps) {
    var sx = 0.0, sy = 0.0, sz = 0.0;
    for (final p in ps) {
      sx += p.x;
      sy += p.y;
      sz += p.z;
    }
    final n = ps.length;
    return Vec3(sx / n, sy / n, sz / n);
  }
}

/// Cámara: gira la escena (yaw en Y, pitch en X) y la proyecta en perspectiva.
/// Pitch positivo = se mira desde arriba (se ven las tapas superiores).
class Camara3D {
  Camara3D({
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required Size tamano,
    this.distancia = 6,
    double escalaBase = 0.36,
    double? ladoReferencia,
  }) : _cy = math.cos(yaw),
       _sy = math.sin(yaw),
       _cp = math.cos(pitch),
       _sp = math.sin(pitch),
       centro = tamano.center(Offset.zero),
       // Por defecto la escala sale del lado menor (la escena cabe completa).
       // Una escena ancha y desplazable pasa su alto como referencia.
       escala = (ladoReferencia ?? tamano.shortestSide) * escalaBase * zoom;

  final double yaw, pitch, zoom, distancia;
  final double _cy, _sy, _cp, _sp;
  final Offset centro;
  final double escala;

  /// Posición del ojo en coordenadas de cámara.
  Vec3 get ojo => Vec3(0, 0, distancia);

  Vec3 aCamara(Vec3 p) {
    final x1 = p.x * _cy + p.z * _sy;
    final z1 = -p.x * _sy + p.z * _cy;
    final y2 = p.y * _cp - z1 * _sp;
    final z2 = p.y * _sp + z1 * _cp;
    return Vec3(x1, y2, z2);
  }

  /// Factor de perspectiva: más cerca (z mayor) = más grande.
  double factor(Vec3 c) => distancia / math.max(0.2, distancia - c.z);

  Offset proyectar(Vec3 c) {
    final f = factor(c) * escala;
    return centro + Offset(c.x * f, -c.y * f);
  }
}

// ---------------------------------------------------------------------------
// Primitivas de la escena
// ---------------------------------------------------------------------------

sealed class Primitiva3D {
  const Primitiva3D({this.id, this.sesgo = 0, this.desplazPx = 0});

  /// Identificador para el toque (null = no se puede tocar).
  final Object? id;

  /// Ajuste de profundidad (positivo = se pinta más adelante).
  final double sesgo;

  /// Desplazamiento horizontal en pantalla, después de proyectar. Sirve para
  /// filas de objetos que giran cada uno en su sitio (cápsulas).
  final double desplazPx;
}

/// Cara plana (polígono). Si [centroSolido] se indica, la cara pertenece a un
/// sólido cerrado: se descarta cuando mira hacia atrás y su normal se orienta
/// hacia afuera del sólido.
class Cara3D extends Primitiva3D {
  const Cara3D(
    this.puntos,
    this.color, {
    this.centroSolido,
    this.sombrear = true,
    this.borde,
    this.anchoBorde = 1,
    super.id,
    super.sesgo,
    super.desplazPx,
  });

  final List<Vec3> puntos;
  final Color color;
  final Vec3? centroSolido;
  final bool sombrear;
  final Color? borde;
  final double anchoBorde;
}

class Linea3D extends Primitiva3D {
  const Linea3D(
    this.a,
    this.b,
    this.color, {
    this.ancho = 1,
    super.sesgo,
    super.desplazPx,
  });

  final Vec3 a, b;
  final Color color;
  final double ancho;
}

/// Punto (círculo en pantalla cuyo radio crece con la perspectiva).
class Punto3D extends Primitiva3D {
  const Punto3D(
    this.p,
    this.radio,
    this.color, {
    this.borde,
    this.anchoBorde = 1.4,
    super.id,
    super.sesgo,
    super.desplazPx,
  });

  final Vec3 p;
  final double radio;
  final Color color;
  final Color? borde;
  final double anchoBorde;
}

/// Texto anclado a un punto 3D (siempre de frente a la cámara).
/// Nunca se sale del lienzo: si no cabe, se corre hacia adentro.
class Texto3D extends Primitiva3D {
  const Texto3D(
    this.p,
    this.texto,
    this.estilo, {
    this.fondo,
    this.punto,
    this.alejarDe,
    this.anchoMax = 140,
    super.sesgo = 1000,
    super.desplazPx,
  });

  final Vec3 p;
  final String texto;
  final TextStyle estilo;
  final Color? fondo;

  /// Si se indica, se dibuja un punto de ese color antes del texto.
  final Color? punto;

  /// Si se indica, el texto se coloca del lado de [p] opuesto a este punto
  /// (p. ej. el centro del radar), en vez de centrado sobre [p].
  final Vec3? alejarDe;

  final double anchoMax;
}

// ---------------------------------------------------------------------------
// Color: sombreado por cara
// ---------------------------------------------------------------------------

/// Luz fija (arriba, a la izquierda y de frente) en coordenadas de cámara.
final Vec3 _luz = const Vec3(-0.35, 0.65, 0.68).normalizado();

/// Cambia solo la intensidad (luminosidad) del mismo color.
Color sombrearColor(Color c, double brillo) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * brillo).clamp(0.0, 1.0)).toColor();
}

// ---------------------------------------------------------------------------
// Pintor
// ---------------------------------------------------------------------------

class _Proyectada {
  _Proyectada(
    this.profundidad,
    this.pintar, {
    this.id,
    this.ruta,
    this.centro,
    this.radio = 0,
  });

  final double profundidad;
  final void Function(Canvas) pintar;
  final Object? id;
  final Path? ruta;
  final Offset? centro;
  final double radio;

  bool contiene(Offset p) {
    if (ruta != null) return ruta!.contains(p);
    if (centro != null) return (p - centro!).distance <= radio + 8;
    return false;
  }
}

/// Lo último que se pintó: sirve para saber qué se tocó.
class ResultadoEscena {
  final List<_Proyectada> _items = [];
  final Map<String, TextPainter> _textos = {};

  /// Devuelve el id del elemento más cercano a la cámara bajo [p].
  Object? buscar(Offset p) {
    for (final it in _items.reversed) {
      if (it.id != null && it.contiene(p)) return it.id;
    }
    return null;
  }

  TextPainter texto(
    String t,
    TextStyle estilo, {
    Color? punto,
    double anchoMax = 140,
  }) {
    final clave = '$t|${estilo.hashCode}|${punto?.toARGB32()}|$anchoMax';
    return _textos.putIfAbsent(
      clave,
      () => TextPainter(
        text: TextSpan(
          style: estilo,
          children: [
            if (punto != null)
              TextSpan(
                text: '● ',
                style: TextStyle(color: punto),
              ),
            TextSpan(text: t),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: anchoMax),
    );
  }

  /// Los números animados crean muchos textos distintos: se vacía la caché
  /// antes de pintar si creció demasiado.
  void _podar() {
    if (_textos.length > 400) liberar();
  }

  void liberar() {
    for (final t in _textos.values) {
      t.dispose();
    }
    _textos.clear();
  }
}

class PintorEscena3D extends CustomPainter {
  PintorEscena3D({
    required this.camara,
    required this.construir,
    required this.resultado,
    super.repaint,
  });

  final Camara3D Function(Size) camara;
  final List<Primitiva3D> Function() construir;
  final ResultadoEscena resultado;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final cam = camara(size);
    resultado._podar();
    final items = resultado._items..clear();

    for (final prim in construir()) {
      final mover = Offset(prim.desplazPx, 0);
      switch (prim) {
        case Cara3D():
          final p = _proyectarCara(prim, cam, mover);
          if (p != null) items.add(p);
        case Linea3D():
          final a = cam.aCamara(prim.a), b = cam.aCamara(prim.b);
          final pa = cam.proyectar(a) + mover, pb = cam.proyectar(b) + mover;
          final pincel = Paint()
            ..color = prim.color
            ..strokeWidth = prim.ancho
            ..style = PaintingStyle.stroke;
          items.add(
            _Proyectada(
              (a.z + b.z) / 2 + prim.sesgo,
              (c) => c.drawLine(pa, pb, pincel),
            ),
          );
        case Punto3D():
          final c3 = cam.aCamara(prim.p);
          final centro = cam.proyectar(c3) + mover;
          final r = prim.radio * cam.factor(c3) * math.sqrt(cam.zoom);
          final relleno = Paint()..color = prim.color;
          final borde = prim.borde == null
              ? null
              : (Paint()
                  ..color = prim.borde!
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = prim.anchoBorde);
          items.add(
            _Proyectada(
              c3.z + prim.sesgo,
              (c) {
                c.drawCircle(centro, r, relleno);
                if (borde != null) c.drawCircle(centro, r, borde);
              },
              id: prim.id,
              centro: centro,
              radio: r,
            ),
          );
        case Texto3D():
          final c3 = cam.aCamara(prim.p);
          var pos = cam.proyectar(c3) + mover;
          final tp = resultado.texto(
            prim.texto,
            prim.estilo,
            punto: prim.punto,
            anchoMax: prim.anchoMax,
          );
          final w = tp.width + 8, h = tp.height + 2;
          if (prim.alejarDe != null) {
            // Se apoya en el punto por el lado de afuera.
            final o = cam.proyectar(cam.aCamara(prim.alejarDe!)) + mover;
            final dir = pos - o;
            final l = dir.distance;
            if (l > 0) {
              pos += Offset(dir.dx / l * w / 2, dir.dy / l * h / 2);
            }
          }
          // Dentro del lienzo siempre.
          pos = Offset(
            pos.dx.clamp(w / 2, math.max(w / 2, size.width - w / 2)),
            pos.dy.clamp(h / 2, math.max(h / 2, size.height - h / 2)),
          );
          final caja = Rect.fromCenter(center: pos, width: w, height: h);
          final fondo = prim.fondo == null
              ? null
              : (Paint()..color = prim.fondo!);
          items.add(
            _Proyectada(c3.z + prim.sesgo, (c) {
              if (fondo != null) {
                c.drawRRect(
                  RRect.fromRectAndRadius(caja, const Radius.circular(6)),
                  fondo,
                );
              }
              tp.paint(c, pos - Offset(tp.width / 2, tp.height / 2));
            }),
          );
      }
    }

    // Algoritmo del pintor: de lo más lejano a lo más cercano.
    items.sort((a, b) => a.profundidad.compareTo(b.profundidad));
    for (final it in items) {
      it.pintar(canvas);
    }
  }

  _Proyectada? _proyectarCara(Cara3D cara, Camara3D cam, Offset mover) {
    if (cara.puntos.length < 3) return null;
    final cs = [for (final p in cara.puntos) cam.aCamara(p)];
    final centro = Vec3.promedio(cs);

    var n = (cs[1] - cs[0]).cruz(cs[2] - cs[0]).normalizado();
    if (cara.centroSolido != null) {
      // Normal hacia afuera del sólido; si mira hacia atrás, no se pinta.
      final s = cam.aCamara(cara.centroSolido!);
      if (n.punto(centro - s) < 0) n = n * -1;
      if (n.punto(cam.ojo - centro) <= 1e-6) return null;
    } else if (n.punto(cam.ojo - centro) < 0) {
      // Cara de dos lados: se sombrea el lado que ve la cámara.
      n = n * -1;
    }

    var color = cara.color;
    if (cara.sombrear) {
      // Frente e iluminadas: más claras; laterales y en sombra: más oscuras.
      color = sombrearColor(color, 0.62 + 0.45 * n.punto(_luz));
    }

    final ruta = Path()
      ..addPolygon([for (final c in cs) cam.proyectar(c) + mover], true);
    final relleno = Paint()..color = color;
    // En caras opacas se repasa el contorno con el mismo color para que no
    // queden rendijas entre caras vecinas.
    final costura = color.a >= 0.99
        ? (Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8)
        : null;
    final borde = cara.borde == null
        ? null
        : (Paint()
            ..color = cara.borde!
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = cara.anchoBorde);

    return _Proyectada(
      centro.z + cara.sesgo,
      (c) {
        c.drawPath(ruta, relleno);
        if (costura != null) c.drawPath(ruta, costura);
        if (borde != null) c.drawPath(ruta, borde);
      },
      id: cara.id,
      ruta: ruta,
    );
  }

  @override
  bool shouldRepaint(covariant PintorEscena3D oldDelegate) => true;
}
