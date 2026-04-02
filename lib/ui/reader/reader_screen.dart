import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../data/database/daos/book_dao.dart';
import '../../data/database/daos/bookmark_dao.dart';
import '../../data/database/daos/read_setting_dao.dart';
import '../../services/read_aloud/read_aloud_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'reader_notifier.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final int initialChapterIndex;

  const ReaderScreen({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showMenu = false;
  bool _showChapterList = false;
  bool _isAutoScrolling = false;
  bool _isReadingAloud = false;
  double _fontSize = 18;
  double _lineHeight = 1.6;
  double _autoScrollSpeed = 1.0;
  String _searchQuery = '';
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;
  int _themeIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final ReadSettingDao _settingDao = ReadSettingDao();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initReadAloud();
  }

  Future<void> _loadSettings() async {
    final setting = await _settingDao.getSetting();
    if (mounted) {
      setState(() {
        _fontSize = setting.fontSize;
        _lineHeight = setting.lineHeight;
        _themeIndex = setting.themeIndex;
      });
    }
  }

  Future<void> _initReadAloud() async {
    final readAloudService = ref.read(readAloudServiceProvider);
    await readAloudService.init();

    readAloudService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isReadingAloud = state == ReadAloudState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    ref.read(readAloudServiceProvider).stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleReadAloud() async {
    final readAloudService = ref.read(readAloudServiceProvider);
    final readerState = ref.read(readerNotifierProvider(widget.book));

    if (_isReadingAloud) {
      await readAloudService.stop();
    } else {
      await readAloudService.start(readerState.currentContent.content);
    }
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });
    if (_isAutoScrolling) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() async {
    while (_isAutoScrolling && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_isAutoScrolling && mounted && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        if (currentScroll < maxScroll) {
          _scrollController.animateTo(
            currentScroll + _autoScrollSpeed,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        } else {
          setState(() {
            _isAutoScrolling = false;
          });
        }
      }
    }
  }

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
    });
  }

  void _toggleChapterList() {
    setState(() {
      _showChapterList = !_showChapterList;
    });
  }

  void _increaseFontSize() async {
    setState(() {
      if (_fontSize < 32) _fontSize += 2;
    });
    await _settingDao.updateFontSize(_fontSize);
  }

  void _decreaseFontSize() async {
    setState(() {
      if (_fontSize > 12) _fontSize -= 2;
    });
    await _settingDao.updateFontSize(_fontSize);
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchIndex = -1;
      });
      return;
    }

    final readerState = ref.read(readerNotifierProvider(widget.book));
    final content = readerState.currentContent.content;
    final results = <int>[];
    int index = 0;
    while (true) {
      index = content.indexOf(query, index);
      if (index == -1) break;
      results.add(index);
      index += query.length;
    }

    setState(() {
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });
  }

  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    });
  }

  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex = _currentSearchIndex > 0
          ? _currentSearchIndex - 1
          : _searchResults.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final readerState = ref.watch(readerNotifierProvider(widget.book));
    final readerNotifier = ref.read(readerNotifierProvider(widget.book).notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // 主内容
          GestureDetector(
            onTap: _toggleMenu,
            child: _buildContent(readerState, readerNotifier, theme),
          ),
          // 顶部菜单
          if (_showMenu) _buildTopMenu(theme),
          // 底部菜单
          if (_showMenu) _buildBottomMenu(readerState, readerNotifier, theme),
          // 章节列表
          if (_showChapterList)
            _buildChapterList(readerState, readerNotifier, theme),
        ],
      ),
    );
  }

  Widget _buildContent(
    ReaderState readerState,
    ReaderNotifier readerNotifier,
    AppThemeData theme,
  ) {
    if (readerState.currentContent.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primary),
      );
    }

    if (readerState.currentContent.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              readerState.currentContent.error!,
              style: TextStyle(color: theme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => readerNotifier.goToChapter(readerState.currentChapterIndex),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 章节标题
          Text(
            readerState.currentContent.title,
            style: TextStyle(
              color: theme.primary,
              fontSize: _fontSize + 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // 正文内容
          Text(
            readerState.currentContent.content,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: _fontSize,
              height: _lineHeight,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTopMenu(AppThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.book.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.textPrimary),
                onPressed: _showSearchDialog,
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: AppColors.textPrimary),
                onPressed: () async {
                  final readerNotifier = ref.read(readerNotifierProvider(widget.book).notifier);
                  await readerNotifier.addBookmark();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('书签已添加')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMenu(
    ReaderState readerState,
    ReaderNotifier readerNotifier,
    AppThemeData theme,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${readerState.currentChapterIndex + 1}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: readerState.chapters.isEmpty
                            ? 0
                            : readerState.currentChapterIndex.toDouble(),
                        max: (readerState.chapters.length - 1).toDouble().clamp(0, double.infinity),
                        onChanged: (value) {
                          readerNotifier.goToChapter(value.toInt());
                        },
                        activeColor: theme.primary,
                        inactiveColor: AppColors.darkBackground,
                      ),
                    ),
                    Text(
                      '${readerState.chapters.length}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // 功能按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMenuButton(
                      icon: Icons.list,
                      label: '目录',
                      onTap: _toggleChapterList,
                    ),
                    _buildMenuButton(
                      icon: _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                      label: '自动',
                      onTap: _toggleAutoScroll,
                    ),
                    _buildMenuButton(
                      icon: _isReadingAloud ? Icons.stop : Icons.volume_up,
                      label: '朗读',
                      onTap: _toggleReadAloud,
                    ),
                    _buildMenuButton(
                      icon: Icons.text_decrease,
                      label: 'A-',
                      onTap: _decreaseFontSize,
                    ),
                    _buildMenuButton(
                      icon: Icons.text_increase,
                      label: 'A+',
                      onTap: _increaseFontSize,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList(
    ReaderState readerState,
    ReaderNotifier readerNotifier,
    AppThemeData theme,
  ) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: 300,
      child: Container(
        color: AppColors.darkSurface,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.darkBackground),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '目录 (${readerState.chapters.length})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: _toggleChapterList,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: readerState.chapters.length,
                itemBuilder: (context, index) {
                  final chapter = readerState.chapters[index];
                  final isCurrent = index == readerState.currentChapterIndex;
                  return ListTile(
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        color: isCurrent ? theme.primary : AppColors.textPrimary,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      readerNotifier.goToChapter(index);
                      _toggleChapterList();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text(
              '搜索正文',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '输入搜索关键词',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold),
                    ),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      _searchQuery = value;
                    });
                    _performSearch(value);
                  },
                ),
                const SizedBox(height: 16),
                if (_searchQuery.isNotEmpty)
                  Text(
                    '找到 ${_searchResults.length} 个匹配',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchResults = [];
                    _currentSearchIndex = -1;
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  '取消',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              if (_searchResults.isNotEmpty) ...[
                TextButton(
                  onPressed: _previousSearchResult,
                  child: const Text(
                    '上一个',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
                TextButton(
                  onPressed: _nextSearchResult,
                  child: const Text(
                    '下一个',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '确定',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
