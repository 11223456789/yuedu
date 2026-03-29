import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class GoldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const GoldCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 2,
      color: backgroundColor ?? AppColors.liujinSurface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.liujinDivider,
          width: 0.5,
        ),
      ),
      margin: margin ?? EdgeInsets.zero,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}
