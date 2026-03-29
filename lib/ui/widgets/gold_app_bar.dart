import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// 鎏金风格 AppBar
class GoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBottomBorder;
  final double elevation;

  const GoldAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBottomBorder = true,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.liujinBackground,
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.liujinPrimary,
                  width: 0.8,
                ),
              )
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.liujinPrimary.withOpacity(0.15),
                  blurRadius: elevation * 2,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.liujinPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        actions: actions,
        iconTheme: const IconThemeData(color: AppColors.liujinPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.liujinPrimary),
      ),
    );
  }
}
