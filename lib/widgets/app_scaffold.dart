import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'gradient_divider.dart';
import 'padel_header.dart';

/// Standard screen shell: navy header + gradient divider + scrollable body,
/// matching every non-auth screen in the design.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.trailing,
    required this.body,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 32),
    this.scrollable = true,
    this.floating,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget body;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final Widget? floating;

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(padding: padding, child: body)
        : Padding(padding: padding, child: body);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            PadelHeader(title: title, subtitle: subtitle, showBack: showBack, onBack: onBack, trailing: trailing),
            const GradientDivider(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: content),
                  if (floating != null) Positioned(left: 0, right: 0, bottom: 0, child: floating!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card container used for form sections throughout the app.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.margin});

  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class SectionCardRow extends StatelessWidget {
  const SectionCardRow({super.key, required this.child, this.showDivider = true});

  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
      ),
      child: child,
    );
  }
}

/// A plain white bordered card (list row, info panel) used outside of
/// [SectionCard]'s grouped-rows layout.
class SimpleCard extends StatelessWidget {
  const SimpleCard({super.key, required this.child, this.padding, this.onTap, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: card);
  }
}
