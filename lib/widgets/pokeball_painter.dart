import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter que dibuja una Pokébola realista
class PokeballPainter extends CustomPainter {
  final Color topColor;
  final Color bottomColor;
  final double opacity;

  const PokeballPainter({
    this.topColor = const Color(0xFFEE1515),
    this.bottomColor = Colors.white,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 1;
    final sw = r * 0.095;
    final btnOuter = r * 0.285;
    final btnInner = r * 0.16;
    final center = Offset(cx, cy);

    // Mitad superior (roja)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      math.pi,
      math.pi,
      true,
      Paint()..color = topColor.withOpacity(opacity),
    );

    // Mitad inferior (blanca)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      0,
      math.pi,
      true,
      Paint()..color = bottomColor.withOpacity(opacity),
    );

    // Franja negra central
    canvas.drawLine(
      Offset(cx - r, cy),
      Offset(cx + r, cy),
      Paint()
        ..color = Colors.black.withOpacity(opacity * 0.85)
        ..strokeWidth = sw,
    );

    // Borde exterior del botón
    canvas.drawCircle(
      center,
      btnOuter,
      Paint()
        ..color = Colors.black.withOpacity(opacity * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    // Relleno del botón
    canvas.drawCircle(
      center,
      btnInner,
      Paint()..color = Colors.white.withOpacity(opacity),
    );

    // Brillo del botón
    canvas.drawCircle(
      Offset(cx - btnInner * 0.3, cy - btnInner * 0.35),
      btnInner * 0.38,
      Paint()..color = Colors.white.withOpacity(opacity * 0.95),
    );

    // Borde exterior de la pokébola
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.black.withOpacity(opacity * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );
  }

  @override
  bool shouldRepaint(PokeballPainter old) =>
      old.opacity != opacity ||
      old.topColor != topColor ||
      old.bottomColor != bottomColor;
}

// ────────────────────────────────────────────────────────────

/// Pokébola giratoria animada — ideal para estados de carga
class SpinningPokeball extends StatefulWidget {
  final double size;
  final Color topColor;

  const SpinningPokeball({
    super.key,
    this.size = 80,
    this.topColor = const Color(0xFFEE1515),
  });

  @override
  State<SpinningPokeball> createState() => _SpinningPokeballState();
}

class _SpinningPokeballState extends State<SpinningPokeball>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _ctrl.value * 2 * math.pi,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: PokeballPainter(topColor: widget.topColor),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────

/// Pokébola semi-transparente para usar como decoración de fondo
class DecorativePokeball extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const DecorativePokeball({
    super.key,
    this.size = 200,
    this.color = Colors.white,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: PokeballPainter(
        topColor: color,
        bottomColor: color,
        opacity: opacity,
      ),
    );
  }
}
