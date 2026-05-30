import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? YGColors.darkSurface : YGColors.lightSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? YGColors.lineDark : YGColors.lineLight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
