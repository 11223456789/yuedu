import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../data/database/daos/rss_source_dao.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import 'rss_article_detail_screen.dart';

class RssArticleListScreen extends ConsumerStatefulWidget {
  final RssSource source;

  const RssArticleListScreen({super.key, required this.source});

  @override
  ConsumerState<RssArticleListScreen> createState() => _RssArticleListScreenState();
}

class _RssArticleListScreenState extends ConsumerState<RssArticleListScreen> {
  final RssArticleDao _dao = RssArticleDao();
  List<RssArticle> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
    });
    
    // 从本地加载已保存的文章
    final articles = await _dao.getArticlesBySource(widget.source.sourceUrl);
    
    setState(() {
      _articles = articles;
      _isLoading = false;
    });

    // 如果没有文章，显示模拟数据
    if (articles.isEmpty) {
      _loadMockArticles();
    }
  }

  void _loadMockArticles() {
    // 模拟RSS文章数据
    final mockArticles = [
      RssArticle(
        origin: widget.source.sourceUrl,
        title: 'Flutter 3.0 正式发布',
        link: 'https://flutter.dev',
        pubDate: '2024-01-15',
        description: 'Flutter 3.0 带来了许多激动人心的新特性和改进...',
        read: false,
      ),
      RssArticle(
        origin: widget.source.sourceUrl,
        title: 'Dart 3 新特性介绍',
        link: 'https://dart.dev',
        pubDate: '2024-01-10',
        description: 'Dart 3 引入了记录类型、模式匹配等强大功能...',
        read: false,
      ),
      RssArticle(
        origin: widget.source.sourceUrl,
        title: '移动开发最佳实践',
        link: 'https://example.com/mobile',
        pubDate: '2024-01-05',
        description: '本文总结了移动应用开发中的最佳实践和常见问题...',
        read: true,
      ),
    ];

    setState(() {
      _articles = mockArticles;
    });
  }

  Future<void> _refreshArticles() async {
    // TODO: 实现真正的RSS文章获取
    _loadMockArticles();
  }

  Future<void> _markAsRead(RssArticle article) async {
    await _dao.markAsRead(widget.source.sourceUrl, article.link);
    setState(() {
      article.read = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: widget.source.sourceName,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshArticles,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : _articles.isEmpty
              ? _buildEmptyView(theme)
              : _buildArticleList(theme),
    );
  }

  Widget _buildEmptyView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: theme.subText),
          const SizedBox(height: 16),
          Text(
            '暂无文章',
            style: TextStyle(color: theme.subText, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角刷新获取最新文章',
            style: TextStyle(color: theme.subText.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList(AppThemeData theme) {
    return RefreshIndicator(
      onRefresh: _refreshArticles,
      color: theme.primary,
      backgroundColor: theme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final article = _articles[index];
          return _buildArticleCard(article, theme);
        },
      ),
    );
  }

  Widget _buildArticleCard(RssArticle article, AppThemeData theme) {
    return Card(
      color: theme.surface,
      child: InkWell(
        onTap: () {
          _markAsRead(article);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RssArticleDetailScreen(
                article: article,
                source: widget.source,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: TextStyle(
                        color: theme.onSurface,
                        fontSize: 16,
                        fontWeight: article.read ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!article.read)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 8, top: 6),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              if (article.description != null && article.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  article.description!,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.subText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    article.pubDate ?? '未知时间',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (article.read)
                    Text(
                      '已读',
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
