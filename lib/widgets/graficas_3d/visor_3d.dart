import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_colors.dart';
import 'motor_3d.dart';

/// Lienzo 3D interactivo, igual para las tres gráficas:
/// - arrastrar = rotar; pellizcar o rueda del mouse = zoom (con límites);
/// - tocar = devuelve el id del elemento tocado (o null si fue en el vacío);
/// - botones de giro automático y de vista inicial;
/// - animación de entrada (0 → 1) que recibe [construir].
/// Los gestos sobre el lienzo no mueven el scroll de la pantalla.
class Visor3D extends StatefulWidget {
  const Visor3D({
    super.key,
    required this.construir,
    required this.alTocar,
    this.alto,
    this.escalaPorAlto = false,
    this.anchoContenido,
    this.yawInicial = -0.6,
    this.pitchInicial = 0.45,
    this.pitchMin = -0.3,
    this.pitchMax = 1.35,
    this.rangoYaw,
    this.distancia = 6,
    this.escalaBase = 0.36,
    this.zoomMin = 0.6,
    this.zoomMax = 2.6,
    this.duracionEntrada = const Duration(milliseconds: 1400),
    this.repintar,
    this.arrastreHorizontalDesplaza = false,
  });

  /// Arma la escena; recibe el avance de la animación de entrada (0 a 1).
  final List<Primitiva3D> Function(double entrada) construir;
  final ValueChanged<Object?> alTocar;

  /// Alto del lienzo; si es null, crece con el ancho (entre 320 y 560).
  final double? alto;

  /// true = la escala sale del alto (escena ancha y desplazable);
  /// false = del lado menor (la escena cabe completa).
  final bool escalaPorAlto;

  /// Ancho de la escena; si no cabe, se desplaza en horizontal.
  final double? anchoContenido;

  final double yawInicial, pitchInicial, pitchMin, pitchMax;

  /// Si se indica, el giro horizontal queda limitado a ese rango y el giro
  /// automático va y viene dentro de él.
  final (double, double)? rangoYaw;

  final double distancia, escalaBase, zoomMin, zoomMax;
  final Duration duracionEntrada;

  /// Animaciones propias de la gráfica que también deben repintar.
  final Listenable? repintar;

  /// Si es true (escena ancha), el arrastre con un dedo o con el mouse se
  /// separa por eje: horizontal = desplazar la escena; vertical = rotar.
  final bool arrastreHorizontalDesplaza;

  @override
  State<Visor3D> createState() => _Visor3DState();
}

class _Visor3DState extends State<Visor3D> with TickerProviderStateMixin {
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: widget.duracionEntrada,
  )..forward();
  late final Animation<double> _entradaCurva = CurvedAnimation(
    parent: _entrada,
    curve: Curves.easeOutCubic,
  );
  late final Ticker _giro = createTicker(_alGirar);
  final _camaraCambio = ValueNotifier<int>(0);
  final _resultado = ResultadoEscena();
  final _scroll = ScrollController();

  late double _yaw = widget.yawInicial;
  late double _pitch = widget.pitchInicial;
  double _zoom = 1;

  bool _girando = false;
  Duration _ultimoTick = Duration.zero;
  double _fase = 0;

  // Estado del gesto en curso.
  bool _arrastrando = false;
  double _zoomInicio = 1;
  Offset _inicio = Offset.zero;
  double _recorrido = 0;
  bool _variosDedos = false;
  Offset _movido = Offset.zero; // desplazamiento total del gesto
  Axis? _eje; // eje fijado del arrastre (modo desplazar/rotar)

  @override
  void dispose() {
    _giro.dispose();
    _entrada.dispose();
    _camaraCambio.dispose();
    _scroll.dispose();
    _resultado.liberar();
    super.dispose();
  }

  void _avisar() => _camaraCambio.value++;

  double _limitarYaw(double y) {
    final r = widget.rangoYaw;
    return r == null ? y : y.clamp(r.$1, r.$2);
  }

  // ---- Giro automático ----------------------------------------------------

  void _alternarGiro() {
    setState(() => _girando = !_girando);
    if (_girando) {
      final r = widget.rangoYaw;
      if (r != null) {
        final medio = (r.$1 + r.$2) / 2, amplitud = (r.$2 - r.$1) / 2;
        _fase = math.asin(((_yaw - medio) / amplitud).clamp(-1.0, 1.0));
      }
      _ultimoTick = Duration.zero;
      _giro.start();
    } else {
      _giro.stop();
    }
  }

  void _alGirar(Duration t) {
    final dt = (t - _ultimoTick).inMicroseconds / 1e6;
    _ultimoTick = t;
    if (_arrastrando) return;
    final r = widget.rangoYaw;
    if (r == null) {
      _yaw += dt * 0.5;
    } else {
      final medio = (r.$1 + r.$2) / 2, amplitud = (r.$2 - r.$1) / 2;
      _fase += dt * 0.7;
      _yaw = medio + amplitud * math.sin(_fase);
    }
    _avisar();
  }

  void _vistaInicial() {
    _yaw = widget.yawInicial;
    _pitch = widget.pitchInicial;
    _zoom = 1;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _avisar();
  }

  // ---- Gestos -------------------------------------------------------------

  void _alEmpezar(ScaleStartDetails d) {
    _arrastrando = true;
    _zoomInicio = _zoom;
    _inicio = d.localFocalPoint;
    _recorrido = 0;
    _variosDedos = d.pointerCount > 1;
    _movido = Offset.zero;
    _eje = null;
    if (_scroll.hasClients) {
      // Detiene un desplazamiento con inercia que siga en curso.
      _scroll.jumpTo(_scroll.offset);
    }
  }

  void _alMover(ScaleUpdateDetails d) {
    if (d.pointerCount > 1) _variosDedos = true;
    _recorrido += d.focalPointDelta.distance;
    if (widget.arrastreHorizontalDesplaza && !_variosDedos) {
      _arrastrePorEje(d.focalPointDelta);
      return;
    }
    if (d.scale != 1.0) {
      _zoom = (_zoomInicio * d.scale).clamp(widget.zoomMin, widget.zoomMax);
    }
    _yaw = _limitarYaw(_yaw + d.focalPointDelta.dx * 0.01);
    _pitch = (_pitch + d.focalPointDelta.dy * 0.01).clamp(
      widget.pitchMin,
      widget.pitchMax,
    );
    _avisar();
  }

  /// Un dedo / mouse en escena ancha: el eje se fija tras unos píxeles.
  /// Horizontal = desplaza la fila (si no hay nada que desplazar, gira);
  /// vertical = rota (inclinación).
  void _arrastrePorEje(Offset delta) {
    _movido += delta;
    if (_eje == null) {
      if (_movido.distance < 6) return;
      _eje = _movido.dx.abs() > _movido.dy.abs()
          ? Axis.horizontal
          : Axis.vertical;
      delta = _movido; // aplica también lo recorrido antes de fijar el eje
    }
    if (_eje == Axis.horizontal) {
      if (_puedeDesplazar) {
        final p = _scroll.position;
        _scroll.jumpTo(
          (p.pixels - delta.dx).clamp(p.minScrollExtent, p.maxScrollExtent),
        );
      } else {
        _yaw = _limitarYaw(_yaw + delta.dx * 0.01);
        _avisar();
      }
    } else {
      _pitch = (_pitch + delta.dy * 0.01).clamp(
        widget.pitchMin,
        widget.pitchMax,
      );
      _avisar();
    }
  }

  bool get _puedeDesplazar =>
      _scroll.hasClients && _scroll.position.maxScrollExtent > 0;

  void _alTerminar(ScaleEndDetails d) {
    _arrastrando = false;
    // Inercia al soltar un arrastre horizontal rápido.
    final vx = d.velocity.pixelsPerSecond.dx;
    if (_eje == Axis.horizontal && _puedeDesplazar && vx.abs() > 150) {
      final p = _scroll.position;
      _scroll.animateTo(
        (p.pixels - vx * 0.35).clamp(p.minScrollExtent, p.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.decelerate,
      );
    }
    // Sin movimiento y con un solo dedo / clic: es un toque.
    if (!_variosDedos && _recorrido < 8) {
      widget.alTocar(_resultado.buscar(_inicio));
    }
  }

  /// Rueda del mouse (o pellizco del trackpad en web) = zoom.
  /// Se reclama el evento para que la pantalla no haga scroll.
  void _alSenal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
        final s = ev as PointerScrollEvent;
        if (s.scrollDelta.dx != 0 && _scroll.hasClients) {
          // Desplazamiento horizontal (shift + rueda o trackpad).
          final p = _scroll.position;
          _scroll.jumpTo(
            (p.pixels + s.scrollDelta.dx).clamp(
              p.minScrollExtent,
              p.maxScrollExtent,
            ),
          );
        }
        if (s.scrollDelta.dy != 0) {
          _zoom = (_zoom * math.exp(-s.scrollDelta.dy * 0.0015)).clamp(
            widget.zoomMin,
            widget.zoomMax,
          );
          _avisar();
        }
      });
    } else if (e is PointerScaleEvent) {
      GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
        _zoom = (_zoom * (ev as PointerScaleEvent).scale).clamp(
          widget.zoomMin,
          widget.zoomMax,
        );
        _avisar();
      });
    }
  }

  // ---- Vista --------------------------------------------------------------

  Widget _lienzo(double ancho, double alto) {
    return Listener(
      onPointerSignal: _alSenal,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _EscalaInmediata:
              GestureRecognizerFactoryWithHandlers<_EscalaInmediata>(
                _EscalaInmediata.new,
                (r) => r
                  ..onStart = _alEmpezar
                  ..onUpdate = _alMover
                  ..onEnd = _alTerminar,
              ),
        },
        child: CustomPaint(
          size: Size(ancho, alto),
          painter: PintorEscena3D(
            repaint: Listenable.merge([
              _camaraCambio,
              _entrada,
              ?widget.repintar,
            ]),
            resultado: _resultado,
            camara: (size) => Camara3D(
              yaw: _yaw,
              pitch: _pitch,
              zoom: _zoom,
              tamano: size,
              distancia: widget.distancia,
              escalaBase: widget.escalaBase,
              ladoReferencia: widget.escalaPorAlto ? size.height : null,
            ),
            construir: () => widget.construir(_entradaCurva.value),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estiloBoton = TextButton.styleFrom(
      foregroundColor: AppColors.azulEncabezado,
      textStyle: Theme.of(context).textTheme.labelMedium
          ?.copyWith(fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            TextButton.icon(
              style: estiloBoton,
              onPressed: _alternarGiro,
              icon: Icon(
                _girando ? Icons.pause_circle_outline : Icons.threesixty,
              ),
              label: Text(_girando ? 'Detener giro' : 'Girar solo'),
            ),
            TextButton.icon(
              style: estiloBoton,
              onPressed: _vistaInicial,
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Vista inicial'),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, c) {
            final alto = widget.alto ?? (c.maxWidth * 0.9).clamp(320.0, 560.0);
            final ancho = math.max(c.maxWidth, widget.anchoContenido ?? 0);
            if (ancho <= c.maxWidth + 0.5) return _lienzo(c.maxWidth, alto);
            // Escena más ancha que la tarjeta: se desplaza en horizontal con la
            // barra inferior, shift + rueda o (si arrastreHorizontalDesplaza)
            // arrastrando de lado sobre la escena.
            return RawScrollbar(
              controller: _scroll,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 8,
              radius: const Radius.circular(4),
              thumbColor: AppColors.azulEncabezado.withValues(alpha: 0.55),
              trackColor: AppColors.campoClaro,
              trackRadius: const Radius.circular(4),
              child: Column(
                children: [
                  SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: _lienzo(ancho, alto),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            widget.arrastreHorizontalDesplaza
                ? 'Arrastra de lado para recorrer · arriba o abajo para girar · '
                      'pellizca o usa la rueda para acercar'
                : 'Arrastra para girar · pellizca o usa la rueda para acercar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.textoGris),
          ),
        ),
      ],
    );
  }
}

/// Reconocedor de escala que gana el gesto apenas se apoya el dedo o el mouse:
/// así arrastrar sobre la gráfica la rota y no mueve el scroll de la pantalla.
class _EscalaInmediata extends ScaleGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
