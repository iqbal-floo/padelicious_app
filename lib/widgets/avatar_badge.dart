import 'package:flutter/material.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    required this.background,
    required this.foreground,
    this.size = 36,
    this.fontSize,
  });

  final String initials;
  final Color background;
  final Color foreground;
  final double size;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: fontSize ?? size * 0.34),
      ),
    );
  }
}

class SmallBadge extends StatelessWidget {
  const SmallBadge(this.text, {super.key, this.background = const Color(0xFFE4F7F7), this.foreground = const Color(0xFF2A9A9A)});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: foreground)),
    );
  }
}
