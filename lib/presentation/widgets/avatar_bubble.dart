import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    super.key,
    required this.avatar,
    required this.size,
    this.selected = false,
    this.frameColor,
    this.glowColor,
    this.badgeEmoji,
  });

  final String avatar;
  final double size;
  final bool selected;
  final Color? frameColor;
  final Color? glowColor;
  final String? badgeEmoji;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? YGColors.darkSurface2 : YGColors.lightSurface2,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? YGColors.gold
                  : (frameColor ?? (isDark ? YGColors.lineDark : YGColors.lineLight)),
              width: selected ? 2.5 : (frameColor != null ? 2.0 : 1.0),
            ),
            boxShadow: glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor!,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Text(
            avatar,
            style: TextStyle(
              fontSize: size * 0.54,
              height: 1.0,
            ),
          ),
        ),
        if (badgeEmoji != null)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  )
                ],
              ),
              child: Text(
                badgeEmoji!,
                style: TextStyle(fontSize: size * 0.28, height: 1.0),
              ),
            ),
          ),
      ],
    );
  }
}
