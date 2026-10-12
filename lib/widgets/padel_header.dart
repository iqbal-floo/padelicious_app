import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular back button for the navy header.
///
/// The visible circle is 40px but the tap target is a full 48px, so taps
/// near the edge still land. A real icon is used rather than a "←" glyph,
/// whose position depends on the font's baseline and sat off-centre.
class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, this.onTap});

  final VoidCallback? onTap;

  static const double _tapSize = 48;
  static const double _circleSize = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: SizedBox.square(
        dimension: _tapSize,
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.10),
            // maybePop: never pops the root route off an empty stack.
            onTap: onTap ?? () => Navigator.of(context).maybePop(),
            child: Center(
              child: Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PillBadge extends StatelessWidget {
  const PillBadge(this.text, {super.key, this.background = AppColors.green, this.foreground = AppColors.navy});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}

/// The navy header bar used at the top of every screen (back button, title,
/// subtitle, optional trailing badge).
class PadelHeader extends StatelessWidget {
  const PadelHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final titleColumn = Column(
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5, height: 1),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teal, letterSpacing: 0.5),
          ),
        ],
      ],
    );

    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.fromLTRB(showBack ? 12 : 20, showBack ? 10 : 14, 20, showBack ? 14 : 18),
      child: Row(
        children: [
          if (showBack) ...[
            BackCircleButton(onTap: onBack),
            const SizedBox(width: 8),
          ],
          Expanded(child: centerTitle ? Center(child: titleColumn) : titleColumn),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
