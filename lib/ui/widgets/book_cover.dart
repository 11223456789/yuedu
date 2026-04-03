import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 书籍封面组件
/// 支持网络图片缓存、本地图片和占位符
class BookCover extends StatelessWidget {
  final String? coverUrl;
  final double width;
  final double height;
  final double borderRadius;
  final AppThemeData theme;
  final IconData placeholderIcon;
  final VoidCallback? onTap;
  final BoxFit fit;

  const BookCover({
    super.key,
    this.coverUrl,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    required this.theme,
    this.placeholderIcon = Icons.menu_book,
    this.onTap,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget coverWidget;

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      // 网络图片
      if (coverUrl!.startsWith('http')) {
        coverWidget = CachedNetworkImage(
          imageUrl: coverUrl!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
          memCacheWidth: (width * 2).toInt(), // 内存缓存优化
          memCacheHeight: (height * 2).toInt(),
        );
      } else {
        // 本地文件图片
        coverWidget = Image.asset(
          coverUrl!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    } else {
      // 无封面，显示占位符
      coverWidget = _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: theme.primary.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          child: coverWidget,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: theme.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          placeholderIcon,
          color: theme.primary.withOpacity(0.5),
          size: width * 0.4,
        ),
      ),
    );
  }
}

/// 书籍封面骨架屏
class BookCoverSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const BookCoverSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// 带阅读进度的书籍封面
class BookCoverWithProgress extends StatelessWidget {
  final String? coverUrl;
  final double width;
  final double height;
  final double progress; // 0.0 - 1.0
  final AppThemeData theme;
  final VoidCallback? onTap;
  final double borderRadius;

  const BookCoverWithProgress({
    super.key,
    this.coverUrl,
    required this.width,
    required this.height,
    this.progress = 0.0,
    required this.theme,
    this.onTap,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BookCover(
          coverUrl: coverUrl,
          width: width,
          height: height,
          borderRadius: borderRadius,
          theme: theme,
          onTap: onTap,
        ),
        if (progress > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(borderRadius),
                ),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(borderRadius),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
