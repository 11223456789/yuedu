import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/daos/book_source_dao.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import 'explore_screen.dart';

/// 发现分类详情页 - 展示某个分类下的书籍列表
class ExploreKindScreen extends ConsumerStatefulWidget {
  final BookSource source;
  final ExploreKind kind;

  const ExploreKindScreen({
    super.key,
    required this.source,
    required this.kind,
  });

  @override
  ConsumerState<ExploreKindScreen> createState() => _ExploreKindScreenState();
}

class _ExploreKindScreenState extends ConsumerState<ExploreKindScreen> {
  bool _isLoading = true;
  List<ExploreBook> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: 实现真正的网络请求获取书籍列表
    // 现在使用模拟数据
    await Future.delayed(const Duration(seconds: 1));

    _books = [
      ExploreBook(
        name: '斗破苍穹',
        author: '天蚕土豆',
        coverUrl: '',
        intro: '这里是斗气的世界，没有花俏艳丽的魔法，有的，仅仅是繁衍到巅峰的斗气！',
        lastChapter: '第一千六百二十三章 结束，也是开始。',
      ),
      ExploreBook(
        name: '完美世界',
        author: '辰东',
        coverUrl: '',
        intro: '一粒尘可填海，一根草斩尽日月星辰，弹指间天翻地覆。',
        lastChapter: '第两千零一十八章 独断万古（大结局）',
      ),
      ExploreBook(
        name: '遮天',
        author: '辰东',
        coverUrl: '',
        intro: '冰冷与黑暗并存的宇宙深处，九具庞大的龙尸拉着一口青铜古棺，亘古长存。',
        lastChapter: '第一千八百二十二章 遮天（大结局）',
      ),
      ExploreBook(
        name: '凡人修仙传',
        author: '忘语',
        coverUrl: '',
        intro: '一个普通山村小子，偶然下进入到当地江湖小门派，成了一名记名弟子。',
        lastChapter: '第两千四百章 飞升仙界（大结局）',
      ),
      ExploreBook(
        name: '仙逆',
        author: '耳根',
        coverUrl: '',
        intro: '顺为凡，逆则仙，只在心中一念间……',
        lastChapter: '第两千零八章 踏天（大结局）',
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: widget.kind.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.primary),
            )
          : _books.isEmpty
              ? _buildEmptyView(theme)
              : _buildBookList(theme),
    );
  }

  Widget _buildEmptyView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: theme.subText,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无书籍',
            style: TextStyle(
              color: theme.subText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(AppThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadBooks,
      color: theme.primary,
      backgroundColor: theme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return _buildBookItem(book, theme);
        },
      ),
    );
  }

  Widget _buildBookItem(ExploreBook book, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: 跳转到书籍详情页
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: book.coverUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.book,
                              color: theme.primary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.book,
                          color: theme.primary,
                          size: 40,
                        ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.intro,
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 14,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.lastChapter,
                              style: TextStyle(
                                color: theme.primary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 发现书籍数据类
class ExploreBook {
  final String name;
  final String author;
  final String coverUrl;
  final String intro;
  final String lastChapter;

  ExploreBook({
    required this.name,
    required this.author,
    required this.coverUrl,
    required this.intro,
    required this.lastChapter,
  });
}
