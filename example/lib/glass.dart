import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "NEAR Terminal" glass design system.
///
/// Deep near-black canvas, drifting mint ambient light behind frosted glass,
/// crisp NEAR-mint accents, a distinctive display face (Unbounded) paired with
/// a clean grotesk body and mono for on-chain data. No gradient fills — depth
/// comes from blur, ambient light, borders and shadow.
class Near {
  // Brand palette
  static const canvas = Color(0xFF06080B);
  static const ink = Color(0xFF0B0E13);
  static const mint = Color(0xFF00EC97); // NEAR signature
  static const mintBright = Color(0xFF6BFFCE);
  static const teal = Color(0xFF0E6E5A);
  static const white = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFFEFF3F8);
  static const textMuted = Color(0xFF8A93A3);
  static const danger = Color(0xFFFF6B6B);

  // Glass tokens
  static Color glassFill = Colors.white.withValues(alpha: 0.055);
  static Color glassFillStrong = Colors.white.withValues(alpha: 0.09);
  static Color glassBorder = Colors.white.withValues(alpha: 0.12);
  static Color glassEdgeLight = Colors.white.withValues(alpha: 0.22);

  // Type scale
  static TextStyle display(
    double size, {
    Color? color,
    FontWeight w = FontWeight.w700,
  }) => GoogleFonts.unbounded(
    fontSize: size,
    fontWeight: w,
    color: color ?? textPrimary,
    height: 1.05,
    letterSpacing: -0.5,
  );
  static TextStyle body(
    double size, {
    Color? color,
    FontWeight w = FontWeight.w400,
  }) => GoogleFonts.hankenGrotesk(
    fontSize: size,
    fontWeight: w,
    color: color ?? textPrimary,
    height: 1.35,
  );
  static TextStyle mono(
    double size, {
    Color? color,
    FontWeight w = FontWeight.w500,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? textPrimary,
    height: 1.4,
    letterSpacing: -0.2,
  );
}

/// A living dark canvas: slowly drifting, heavily-blurred mint ambient lights
/// over a faint dot grid + grain. Sits behind the whole app.
class AnimatedGlassBackground extends StatefulWidget {
  const AnimatedGlassBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedGlassBackground> createState() =>
      _AnimatedGlassBackgroundState();
}

class _AnimatedGlassBackgroundState extends State<AnimatedGlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Near.canvas,
      child: Stack(
        children: [
          // Drifting ambient light (blurred solid orbs = lighting, not gradient fills)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * 2 * math.pi;
              return Stack(
                children: [
                  _orb(
                    math.sin(t) * 0.30 + 0.18,
                    math.cos(t * 0.8) * 0.18 + 0.10,
                    Near.mint,
                    340,
                    0.16,
                  ),
                  _orb(
                    math.cos(t * 0.7) * 0.30 + 0.78,
                    math.sin(t) * 0.20 + 0.30,
                    Near.teal,
                    420,
                    0.30,
                  ),
                  _orb(
                    math.sin(t * 1.1) * 0.22 + 0.55,
                    math.cos(t) * 0.22 + 0.85,
                    Near.mint,
                    300,
                    0.10,
                  ),
                ],
              );
            },
          ),
          // Faint dot grid + grain
          const Positioned.fill(child: IgnorePointer(child: _TexturePainter())),
          widget.child,
        ],
      ),
    );
  }

  Widget _orb(double fx, double fy, Color color, double size, double opacity) {
    return Align(
      alignment: Alignment(fx * 2 - 1, fy * 2 - 1),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class _TexturePainter extends StatelessWidget {
  const _TexturePainter();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotGridPainter());
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.025);
    const gap = 34.0;
    for (double y = 0; y < size.height; y += gap) {
      for (double x = 0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.0, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A frosted glass panel. [blur] enables a real backdrop blur (use for hero /
/// few-instance surfaces); when false it uses a translucent fill that reads as
/// glass over the animated canvas (cheap — safe for long lists).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.blur = false,
    this.glow,
    this.strong = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool blur;
  final Color? glow;
  final bool strong;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final fill = strong ? Near.glassFillStrong : Near.glassFill;
    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Near.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.22),
              blurRadius: 34,
              spreadRadius: -6,
            ),
        ],
      ),
      child: child,
    );
    if (blur) {
      panel = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: panel,
        ),
      );
    }
    return panel;
  }
}

/// Staggered fade + rise entrance. Wrap list items; pass an increasing [index].
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0, this.dy = 18});
  final Widget child;
  final int index;
  final double dy;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, widget.dy * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Press-responsive wrapper: subtle scale-down + optional mint glow on tap.
class PressFx extends StatefulWidget {
  const PressFx({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressFx> createState() => _PressFxState();
}

class _PressFxState extends State<PressFx> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The NEAR "N" mark drawn as a glowing glass token.
class NearMark extends StatelessWidget {
  const NearMark({super.key, this.size = 36});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Near.mint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Near.mint.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Near.mint.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: CustomPaint(painter: _NPainter()),
    );
  }
}

class _NPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Near.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.30, h * 0.72)
      ..lineTo(w * 0.30, h * 0.28)
      ..lineTo(w * 0.70, h * 0.72)
      ..lineTo(w * 0.70, h * 0.28);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A primary action rendered as a solid mint glass pill with press feedback.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return PressFx(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: filled
              ? Near.mint.withValues(alpha: disabled ? 0.25 : 1)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: filled ? null : Border.all(color: Near.glassBorder, width: 1),
          boxShadow: filled && !disabled
              ? [
                  BoxShadow(
                    color: Near.mint.withValues(alpha: 0.35),
                    blurRadius: 26,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(
                    filled ? Near.canvas : Near.mint,
                  ),
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 18, color: filled ? Near.canvas : Near.mint),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: Near.body(
                  15,
                  w: FontWeight.w700,
                  color: filled ? Near.canvas : Near.mint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A subtle pill chip (e.g. network badge).
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.color = Near.mint,
    this.dot = true,
  });
  final String label;
  final Color color;
  final bool dot;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [BoxShadow(color: color, blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: Near.mono(11, color: color, w: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
