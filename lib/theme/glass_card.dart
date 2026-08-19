import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// A reusable glassmorphism container: blurred backdrop + translucent fill.
/// Use this in place of a plain Container(decoration: AppTheme.cardDecoration())
/// wherever you want the frosted-glass look.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlighted;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: AppTheme.glassDecoration(radius: radius, highlighted: highlighted),
          child: child,
        ),
      ),
    );
  }
}