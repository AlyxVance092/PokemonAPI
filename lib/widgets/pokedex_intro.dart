import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Opens the full-screen Pokédex doors to reveal the real app underneath.
class PokedexIntro extends StatefulWidget {
  const PokedexIntro({super.key, required this.child});

  final Widget child;

  @override
  State<PokedexIntro> createState() => _PokedexIntroState();
}

class _PokedexIntroState extends State<PokedexIntro>
    with TickerProviderStateMixin {
  late final AnimationController _doorController;
  late final AnimationController _waveController;
  late final Animation<double> _doorProgress;
  late final Animation<double> _zoom;

  Offset _tapPosition = Offset.zero;
  bool _opening = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _doorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _doorProgress = CurvedAnimation(
      parent: _doorController,
      curve: Curves.bounceOut,
    );
    _zoom = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.94,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 74,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 26,
      ),
    ]).animate(_doorController);
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _doorController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening || _revealed) return;
    setState(() => _opening = true);
    _waveController.forward(from: 0);
    await _doorController.forward();
    if (!mounted) return;
    setState(() {
      _revealed = true;
      _opening = false;
    });
  }

  Future<void> _close() async {
    if (!_revealed || _opening) return;
    setState(() => _opening = true);
    _waveController.reverse();
    await _doorController.reverse();
    if (!mounted) return;
    setState(() {
      _revealed = false;
      _opening = false;
    });
  }

  void _rememberTap(TapDownDetails details) {
    _tapPosition = details.localPosition;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_revealed && !_opening,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _revealed && !_opening) _close();
      },
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          const ColoredBox(color: Color(0xFF0B0D17)),
          AnimatedBuilder(
            animation: _doorController,
            child: widget.child,
            builder: (context, child) {
              final progress = _doorController.value;
              final radius = 22 * (1 - progress);
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Transform.scale(scale: _zoom.value, child: child),
              );
            },
          ),
          if (!_revealed || _opening) Positioned.fill(child: _buildDoors()),
        ],
      ),
    );
  }

  Widget _buildDoors() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final halfWidth = size.width / 2 + 2;
        return GestureDetector(
          onTapDown: _opening ? null : _rememberTap,
          onTap: _opening ? null : _open,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _doorProgress,
                builder: (context, _) {
                  final progress = _doorProgress.value;
                  return Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      _buildDoor(
                        isLeft: true,
                        progress: progress,
                        width: halfWidth,
                      ),
                      _buildDoor(
                        isLeft: false,
                        progress: progress,
                        width: halfWidth,
                      ),
                      Positioned(
                        left: size.width / 2 - 3,
                        top: 0,
                        bottom: 0,
                        width: 6,
                        child: Opacity(
                          opacity: (1 - progress).clamp(0.0, 1.0).toDouble(),
                          child: const ColoredBox(color: Color(0xFF4B1017)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) => _buildWave(size),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoor({
    required bool isLeft,
    required double progress,
    required double width,
  }) {
    final angle = progress * math.pi * 0.54;
    final opacity = ((1 - progress) / 0.17).clamp(0.0, 1.0).toDouble();
    final direction = isLeft ? -1.0 : 1.0;

    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: width,
      child: Transform.translate(
        offset: Offset(direction * width * progress * 0.78, 0),
        child: Opacity(
          opacity: opacity,
          child: Transform(
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(isLeft ? -angle : angle),
            child: _doorPanel(isLeft: isLeft),
          ),
        ),
      ),
    );
  }

  Widget _doorPanel({required bool isLeft}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [
            Color(0xFFE31D2D),
            Color(0xFFC91525),
            Color(0xFFB90E20),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: isLeft ? null : 0,
            right: isLeft ? 0 : null,
            width: 7,
            child: const ColoredBox(color: Color(0x66500A12)),
          ),
          Align(
            alignment: Alignment(isLeft ? 0.77 : -0.77, 0.08),
            child: Container(
              width: 38,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF7D111B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF540D15), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 8,
                    offset: Offset(2, 3),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 11,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC928),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC928).withOpacity(0.35),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: ColoredBox(color: Colors.white.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  Widget _buildWave(Size size) {
    if (_waveController.isDismissed) return const SizedBox.shrink();

    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final baseDiameter = diagonal * 2.1;
    final waves = <Widget>[];

    for (var index = 0; index < 2; index++) {
      final delay = index * 0.16;
      final localProgress = ((_waveController.value - delay) / (1 - delay))
          .clamp(0.0, 1.0)
          .toDouble();
      if (localProgress == 0 && index > 0) continue;
      final easedProgress = Curves.easeOut.transform(localProgress);
      final diameter = 28 + baseDiameter * easedProgress;
      final opacity = (0.76 * (1 - easedProgress)).clamp(0.0, 0.76).toDouble();
      waves.add(
        Positioned(
          left: _tapPosition.dx - diameter / 2,
          top: _tapPosition.dy - diameter / 2,
          width: diameter,
          height: diameter,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF73F5FF),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAA42DFFF),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(clipBehavior: Clip.none, children: waves);
  }
}
