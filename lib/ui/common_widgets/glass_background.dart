import 'package:flutter/material.dart';

import '../../core/theme/cyber_colors.dart';

/// Solid theme background retained as a compatibility wrapper.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: CyberColors.background(context), child: child);
  }
}
