import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// 鎏金描边按钮
class GoldBorderButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool filled;
  final double? width;

  const GoldBorderButton({
    super.key,
    required this.text,
    this.onPressed,
    this.filled = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [AppColors.liujinAccent, AppColors.liujinPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: Border.all(color: AppColors.liujinPrimary, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: filled
                ? AppColors.liujinBackground
                : AppColors.liujinPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
