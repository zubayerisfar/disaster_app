import 'package:flutter/material.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const kCardBg = Colors.white;
const kCardBorder = Color(0xFFE0E7FF);
const kAccentBlue = Color(0xFF1565C0);
const kBgColor = Color(0xFFF4F6FA); // very light grey-white page background

// kept for AppBar/NavBar border line
const kGlassBorder = Color(0xFFDDE3F0);

// ── Card widget (clean flat white card) ───────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: borderRadius,
        border: Border.all(color: kCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
