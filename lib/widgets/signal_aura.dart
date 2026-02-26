import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';

/// Pulsing edge-glow overlay shown on all screens when warning level > 4.
/// Uses [IgnorePointer] so it never blocks touches.
class SignalAuraOverlay extends StatefulWidget {
  const SignalAuraOverlay({super.key});

  @override
  State<SignalAuraOverlay> createState() => _SignalAuraOverlayState();
}

class _SignalAuraOverlayState extends State<SignalAuraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _colorForLevel(int level) {
    if (level <= 6) return const Color(0xFFFF6D00); // deep-orange  (5-6)
    if (level <= 8) return const Color(0xFFE53935); // red          (7-8)
    return const Color(0xFFB71C1C); //               dark red       (9-10)
  }

  @override
  Widget build(BuildContext context) {
    final level = context.watch<WeatherProvider>().warningLevel;
    if (level <= 4) return const SizedBox.shrink();

    final base = _colorForLevel(level);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          // Smooth breathing: opacity between 0.30 and 0.80
          final t = Curves.easeInOut.transform(_ctrl.value);
          final opacity = 0.30 + t * 0.50;
          final glow = base.withOpacity(opacity);
          final clear = base.withOpacity(0.0);
          const edgeW = 64.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: edgeW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [glow, clear],
                    ),
                  ),
                ),
              ),
              // Bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: edgeW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [glow, clear],
                    ),
                  ),
                ),
              ),
              // Left
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: edgeW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [glow, clear],
                    ),
                  ),
                ),
              ),
              // Right
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: edgeW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [glow, clear],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
