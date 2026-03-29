import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// 鎏金渐变分割线
class GoldDivider extends StatelessWidget {
  final double height;
  final double indent;
  final double endIndent;

  const GoldDivider({
    super.key,
    this.height = 1.0,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.liujinDivider,
            AppColors.liujinPrimary,
            AppColors.liujinDivider,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
