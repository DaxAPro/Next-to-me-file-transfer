import 'package:flutter/material.dart';

import '../../core/theme/cyber_colors.dart';

/// Flat, bordered surface kept under its original name for compatibility.
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
    final rRadius = borderRadius ?? BorderRadius.circular(16);
    final content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : rRadius,
        color: color ?? CyberColors.surface(context),
        border: border ?? Border.all(color: CyberColors.border(context)),
      ),
      child: child,
    );

    Widget surface = content;

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    if (onTap != null) {
      surface = InkWell(
        onTap: onTap,
        borderRadius: shape == BoxShape.circle
            ? BorderRadius.circular(999)
            : rRadius,
        child: surface,
      );
    }

    return surface;
  }
}
