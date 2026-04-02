import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../data/database/daos/rss_source_dao.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';

class RssArticleDetailScreen extends ConsumerWidget {
  final RssArticle article;
  final RssSource source;

  const RssArticleDetailScreen({
    super.key,
    required this.article,
    required this.source,
  });

  Future<void> _openInBrowser(BuildContext context) async {
    final uri = Uri.parse(article.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '文章详情',
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _openInBrowser(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 分享文章
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              article.title,
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 元信息
            Row(
              children: [
                Icon(Icons.source, size: 16, color: theme.subText),
                const SizedBox(width: 4),
                Text(
                  source.sourceName,
                  style: TextStyle(color: theme.subText, fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: theme.subText),
                const SizedBox(width: 4),
                Text(
                  article.pubDate ?? '未知时间',
                  style: TextStyle(color: theme.subText, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // 内容
            if (article.content != null && article.content!.isNotEmpty)
              Text(
                article.content!,
                style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 16,
                  height: 1.6,
                ),
              )
            else if (article.description != null && article.description!.isNotEmpty)
              Text(
                article.description!,
                style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 16,
                  height: 1.6,
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(Icons.article_outlined, size: 64, color: theme.subText),
                    const SizedBox(height: 16),
                    Text(
                      '暂无内容',
                      style: TextStyle(color: theme.subText),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _openInBrowser(context),
                      child: const Text('在浏览器中打开'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
