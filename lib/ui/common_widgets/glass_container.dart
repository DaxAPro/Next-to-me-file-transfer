import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium Frosted Glassmorphism Container with backdrop blur and luminous sheen.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final BoxShape shape;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 12.0,
    this.color,
    this.border,
    this.shape = BoxShape.rectangle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rRadius = borderRadius ?? BorderRadius.circular(16);

    // Glass frosted gradient & sheen
    final defaultGlassColor = isDark
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.72);

    final glassBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        );

    final content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : rRadius,
        color: color ?? defaultGlassColor,
        border: glassBorder,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    Widget frosted = ClipRRect(
      borderRadius: shape == BoxShape.circle ? BorderRadius.circular(999) : rRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );

    if (margin != null) {
      frosted = Padding(padding: margin!, child: frosted);
    }

    if (onTap != null) {
      frosted = InkWell(
        onTap: onTap,
        borderRadius: shape == BoxShape.circle ? BorderRadius.circular(999) : rRadius,
        child: frosted,
      );
    }

    return frosted;
  }
}
