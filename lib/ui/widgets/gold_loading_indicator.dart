import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class GoldLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const GoldLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.liujinPrimary),
        strokeWidth: strokeWidth,
      ),
    );
  }
}
