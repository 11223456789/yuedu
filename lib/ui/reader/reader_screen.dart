import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/daos/book_dao.dart';
import '../../data/database/daos/bookmark_dao.dart';
import '../../data/database/daos/read_record_dao.dart';
import '../../data/database/daos/read_setting_dao.dart';
import '../../model/web_book/web_book.dart';
import '../../services/read_aloud/read_aloud_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'page_turn_animation.dart';
import 'reader_font.dart';
import 'reader_notifier.dart';
import 'reader_theme.dart';

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

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with TickerProviderStateMixin {
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
  int _fontIndex = 0;
  PageTurnMode _pageTurnMode = PageTurnMode.cover;

  // 阅读时间记录
  DateTime? _startReadTime;
  int _readWords = 0;
  Timer? _readTimer;

  // 音量键翻页
  bool _volumeKeyTurnPage = true;

  final ScrollController _scrollController = ScrollController();
  final ReadSettingDao _settingDao = ReadSettingDao();
  final ReadRecordDao _readRecordDao = ReadRecordDao();
  late final PageTurnController _pageTurnController;

  @override
  void initState() {
    super.initState();
    _pageTurnController = PageTurnController();
    _pageTurnController.attach(this);
    _loadSettings();
    _initReadAloud();
    _startReading();
  }

  /// 开始阅读计时
  void _startReading() {
    _startReadTime = DateTime.now();
    _readWords = 0;
    
    // 每30秒保存一次阅读记录
    _readTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveReadRecord();
    });
  }

  /// 保存阅读记录
  void _saveReadRecord() async {
    if (_startReadTime == null) return;
    
    final now = DateTime.now();
    final duration = now.difference(_startReadTime!);
    final seconds = duration.inSeconds;
    
    if (seconds > 0 && _readWords > 0) {
      await _readRecordDao.recordReadTime(
        widget.book.bookUrl,
        widget.book.name,
        seconds,
        _readWords,
      );
      
      // 重置计时
      _startReadTime = now;
      _readWords = 0;
    }
  }

  Future<void> _loadSettings() async {
    final setting = await _settingDao.getSetting();
    if (mounted) {
      setState(() {
        _fontSize = setting.fontSize;
        _lineHeight = setting.lineHeight;
        _themeIndex = setting.themeIndex;
        _fontIndex = _getFontIndex(setting.fontFamily);
        _pageTurnMode = PageTurnModeExtension.fromValue(setting.pageTurnMode);
        _volumeKeyTurnPage = setting.volumeKeyTurnPage;
      });
      _pageTurnController.setMode(_pageTurnMode);
    }
  }

  int _getFontIndex(String fontFamily) {
    for (int i = 0; i < ReaderFont.allFonts.length; i++) {
      if (ReaderFont.allFonts[i].fontFamily == fontFamily) {
        return i;
      }
    }
    return 0;
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
    _saveReadRecord(); // 保存最后一次阅读记录
    _readTimer?.cancel();
    ref.read(readAloudServiceProvider).stop();
    _pageTurnController.detach();
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

  void _increaseLineHeight() async {
    setState(() {
      if (_lineHeight < 2.5) _lineHeight += 0.2;
    });
    await _settingDao.updateLineHeight(_lineHeight);
  }

  void _decreaseLineHeight() async {
    setState(() {
      if (_lineHeight > 1.0) _lineHeight -= 0.2;
    });
    await _settingDao.updateLineHeight(_lineHeight);
  }

  void _changeTheme(int index) async {
    setState(() {
      _themeIndex = index;
    });
    final theme = ReaderTheme.getThemeByIndex(index);
    await _settingDao.updateTheme(index, theme.textColor.value, theme.backgroundColor.value);
  }

  void _changePageTurnMode(PageTurnMode mode) async {
    setState(() {
      _pageTurnMode = mode;
    });
    _pageTurnController.setMode(mode);
    await _settingDao.updatePageTurnMode(mode.value);
  }

  void _showPageTurnModePicker() {
    final theme = ref.read(themeNotifierProvider);
    final readerTheme = ReaderTheme.getThemeByIndex(_themeIndex);
    showModalBottomSheet(
      context: context,
      backgroundColor: readerTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '翻页模式',
                  style: TextStyle(
                    color: readerTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: PageTurnMode.values.map((mode) {
                    final isSelected = _pageTurnMode == mode;
                    return GestureDetector(
                      onTap: () {
                        _changePageTurnMode(mode);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? readerTheme.primaryColor : readerTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? readerTheme.primaryColor : readerTheme.textColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          mode.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : readerTheme.textColor,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFontPicker() {
    final readerTheme = ReaderTheme.getThemeByIndex(_themeIndex);
    showModalBottomSheet(
      context: context,
      backgroundColor: readerTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择字体 (${ReaderFont.allFonts.length}种)',
                  style: TextStyle(
                    color: readerTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击预览，长按应用',
                  style: TextStyle(
                    color: readerTheme.textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                // 字体分类显示
                _buildFontCategory(
                  '系统字体',
                  [0], // 系统默认
                  readerTheme,
                ),
                const SizedBox(height: 16),
                _buildFontCategory(
                  '开源字体',
                  [1, 2, 3, 4, 5], // 思源宋体、思源黑体、霞鹜文楷、站酷文艺、阿里巴巴
                  readerTheme,
                ),
                const SizedBox(height: 16),
                _buildFontCategory(
                  '传统字体',
                  [6, 7, 8, 9, 10], // 仿宋、新魏、楷体、宋体、黑体
                  readerTheme,
                ),
                const SizedBox(height: 16),
                _buildFontCategory(
                  '华文字体',
                  [11, 12, 13, 14], // 微软雅黑、华文细黑、华文楷体、华文宋体
                  readerTheme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontCategory(String title, List<int> fontIndices, ReaderTheme readerTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: readerTheme.textColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fontIndices.map((index) {
            final font = ReaderFont.getFontByIndex(index);
            final isSelected = _fontIndex == index;
            return GestureDetector(
              onTap: () {
                _changeFont(index);
              },
              onLongPress: () {
                _changeFont(index);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? readerTheme.primaryColor : readerTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? readerTheme.primaryColor : readerTheme.textColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  font.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : readerTheme.textColor,
                    fontSize: 14,
                    fontFamily: font.fontFamily.isEmpty ? null : font.fontFamily,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _changeFont(int index) async {
    setState(() {
      _fontIndex = index;
    });
    final font = ReaderFont.getFontByIndex(index);
    await _settingDao.updateFontFamily(font.fontFamily);
  }

  void _goToPreviousChapter() {
    final readerNotifier = ref.read(readerNotifierProvider(widget.book).notifier);
    final readerState = ref.read(readerNotifierProvider(widget.book));
    if (readerState.currentChapterIndex > 0) {
      _pageTurnController.animateBackward().then((_) {
        readerNotifier.goToChapter(readerState.currentChapterIndex - 1);
      });
    }
  }

  void _goToNextChapter() {
    final readerNotifier = ref.read(readerNotifierProvider(widget.book).notifier);
    final readerState = ref.read(readerNotifierProvider(widget.book));
    if (readerState.currentChapterIndex < readerState.chapters.length - 1) {
      _pageTurnController.animateForward().then((_) {
        readerNotifier.goToChapter(readerState.currentChapterIndex + 1);
      });
    } else {
      // 已经是最后一章，显示阅读完成提示
      _showBookCompletedDialog();
    }
  }

  void _showBookCompletedDialog() {
    final readerTheme = ReaderTheme.getThemeByIndex(_themeIndex);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: readerTheme.backgroundColor,
        title: Text(
          '🎉 恭喜完成阅读',
          style: TextStyle(
            color: readerTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: readerTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '你已经读完了《${widget.book.name}》',
              style: TextStyle(
                color: readerTheme.textColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${widget.book.totalChapterNum} 章',
              style: TextStyle(
                color: readerTheme.textColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(color: readerTheme.textColor.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 返回书架
              Navigator.pop(context);
            },
            child: Text(
              '返回书架',
              style: TextStyle(color: readerTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    final readerState = ref.read(readerNotifierProvider(widget.book));
    final readerTheme = ReaderTheme.getThemeByIndex(_themeIndex);
    final currentChapter = readerState.chapters.isNotEmpty
        ? readerState.chapters[readerState.currentChapterIndex].title
        : '';
    final progress = readerState.chapters.isNotEmpty
        ? ((readerState.currentChapterIndex + 1) / readerState.chapters.length * 100).toStringAsFixed(1)
        : '0';

    showModalBottomSheet(
      context: context,
      backgroundColor: readerTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分享阅读',
                  style: TextStyle(
                    color: readerTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // 分享内容预览
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: readerTheme.textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: readerTheme.textColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '《${widget.book.name}》',
                        style: TextStyle(
                          color: readerTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '作者：${widget.book.author}',
                        style: TextStyle(
                          color: readerTheme.textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '正在阅读：$currentChapter',
                        style: TextStyle(
                          color: readerTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '阅读进度：$progress%',
                        style: TextStyle(
                          color: readerTheme.textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 分享按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareButton(
                      icon: Icons.content_copy,
                      label: '复制',
                      onTap: () {
                        final shareText = '''我正在阅读《${widget.book.name}》
作者：${widget.book.author}
当前章节：$currentChapter
阅读进度：$progress%

来自佩宇书屋''';
                        // TODO: 复制到剪贴板
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板')),
                        );
                      },
                      readerTheme: readerTheme,
                    ),
                    _buildShareButton(
                      icon: Icons.chat,
                      label: '微信',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('分享功能开发中')),
                        );
                      },
                      readerTheme: readerTheme,
                    ),
                    _buildShareButton(
                      icon: Icons.camera_alt,
                      label: '生成图片',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('生成图片功能开发中')),
                        );
                      },
                      readerTheme: readerTheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ReaderTheme readerTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: readerTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              icon,
              color: readerTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: readerTheme.textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker() {
    final theme = ref.read(themeNotifierProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择主题',
                  style: TextStyle(
                    color: theme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ReaderTheme.allThemes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final readerTheme = entry.value;
                    final isSelected = _themeIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _changeTheme(index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 80,
                        height: 100,
                        decoration: BoxDecoration(
                          color: readerTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? readerTheme.primaryColor : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Aa',
                              style: TextStyle(
                                color: readerTheme.textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              readerTheme.name,
                              style: TextStyle(
                                color: readerTheme.textColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReaderSettings() {
    final readerTheme = ReaderTheme.getThemeByIndex(_themeIndex);
    showModalBottomSheet(
      context: context,
      backgroundColor: readerTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '阅读设置',
                  style: TextStyle(
                    color: readerTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // 字体选择
                _buildSettingItem(
                  readerTheme: readerTheme,
                  icon: Icons.font_download,
                  title: '字体',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showFontPicker();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: readerTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ReaderFont.getFontByIndex(_fontIndex).name,
                        style: TextStyle(
                          color: readerTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                // 字体大小
                _buildSettingItem(
                  readerTheme: readerTheme,
                  icon: Icons.text_fields,
                  title: '字体大小',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: readerTheme.textColor),
                        onPressed: _decreaseFontSize,
                      ),
                      Text(
                        '${_fontSize.toInt()}',
                        style: TextStyle(color: readerTheme.textColor, fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: readerTheme.textColor),
                        onPressed: _increaseFontSize,
                      ),
                    ],
                  ),
                ),
                // 行间距
                _buildSettingItem(
                  readerTheme: readerTheme,
                  icon: Icons.format_line_spacing,
                  title: '行间距',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: readerTheme.textColor),
                        onPressed: _decreaseLineHeight,
                      ),
                      Text(
                        '${_lineHeight.toStringAsFixed(1)}',
                        style: TextStyle(color: readerTheme.textColor, fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: readerTheme.textColor),
                        onPressed: _increaseLineHeight,
                      ),
                    ],
                  ),
                ),
                // 翻页模式
                _buildSettingItem(
                  readerTheme: readerTheme,
                  icon: Icons.auto_stories,
                  title: '翻页模式',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showPageTurnModePicker();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: readerTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _pageTurnMode.displayName,
                        style: TextStyle(
                          color: readerTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                // 音量键翻页
                _buildSettingItem(
                  readerTheme: readerTheme,
                  icon: Icons.volume_up,
                  title: '音量键翻页',
                  child: Switch(
                    value: _volumeKeyTurnPage,
                    onChanged: (value) async {
                      setState(() {
                        _volumeKeyTurnPage = value;
                      });
                      final setting = await _settingDao.getSetting();
                      await _settingDao.saveSetting(setting.copyWith(volumeKeyTurnPage: value));
                    },
                    activeColor: readerTheme.primaryColor,
                  ),
                ),
                // 主题
                _buildSettingItem(
                  readerTheme: readerTheme,
                  icon: Icons.color_lens,
                  title: '阅读主题',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showThemePicker();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: readerTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        readerTheme.name,
                        style: TextStyle(
                          color: readerTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required ReaderTheme readerTheme,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: readerTheme.textColor.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: readerTheme.textColor,
                fontSize: 15,
              ),
            ),
          ),
          child,
        ],
      ),
    );
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
    final readerTheme = ReaderTheme.getThemeByIndex(_themeIndex);

    return Scaffold(
      backgroundColor: readerTheme.backgroundColor,
      body: Stack(
        children: [
          // 主内容
          PageTurnGestureDetector(
            onTapCenter: _toggleMenu,
            onTapLeft: _goToPreviousChapter,
            onTapRight: _goToNextChapter,
            onSwipeLeft: _goToNextChapter,
            onSwipeRight: _goToPreviousChapter,
            child: _buildContent(readerState, readerNotifier, theme, readerTheme),
          ),
          // 顶部菜单
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            top: _showMenu ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildTopMenu(theme, readerTheme),
          ),
          // 底部菜单
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            bottom: _showMenu ? 0 : -150,
            left: 0,
            right: 0,
            child: _buildBottomMenu(readerState, readerNotifier, theme, readerTheme),
          ),
          // 章节列表
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            right: _showChapterList ? 0 : -300,
            width: 300,
            child: _buildChapterList(readerState, readerNotifier, theme, readerTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ReaderState readerState,
    ReaderNotifier readerNotifier,
    AppThemeData theme,
    ReaderTheme readerTheme,
  ) {
    if (readerState.currentContent.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: readerTheme.primaryColor),
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
              color: readerTheme.primaryColor,
              fontSize: _fontSize + 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // 正文内容
          Builder(
            builder: (context) {
              // 统计字数
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _readWords += readerState.currentContent.content.length;
              });
              return Text(
                readerState.currentContent.content,
                style: TextStyle(
                  color: readerTheme.textColor,
                  fontSize: _fontSize,
                  height: _lineHeight,
                  fontFamily: ReaderFont.getFontByIndex(_fontIndex).fontFamily.isEmpty
                      ? null
                      : ReaderFont.getFontByIndex(_fontIndex).fontFamily,
                ),
              );
            }
          ),
          const SizedBox(height: 100),
          // 阅读进度
          if (readerState.chapters.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // 进度条
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: readerTheme.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (readerState.currentChapterIndex + 1) / readerState.chapters.length,
                      child: Container(
                        decoration: BoxDecoration(
                          color: readerTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 进度文字
                  Text(
                    '${readerState.currentChapterIndex + 1} / ${readerState.chapters.length} 章 · ${((readerState.currentChapterIndex + 1) / readerState.chapters.length * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: readerTheme.textColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopMenu(AppThemeData theme, ReaderTheme readerTheme) {
    return Container(
      decoration: BoxDecoration(
        color: readerTheme.backgroundColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: readerTheme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.book.name,
                style: TextStyle(
                  color: readerTheme.textColor,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: readerTheme.textColor),
              onPressed: _showReaderSettings,
            ),
            IconButton(
              icon: Icon(Icons.search, color: readerTheme.textColor),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: Icon(Icons.share, color: readerTheme.textColor),
              onPressed: _showShareDialog,
            ),
            IconButton(
              icon: Icon(Icons.bookmark_border, color: readerTheme.textColor),
              onPressed: () async {
                final readerNotifier = ref.read(readerNotifierProvider(widget.book).notifier);
                await readerNotifier.addBookmark();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('书签已添加'),
                      backgroundColor: readerTheme.primaryColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMenu(
    ReaderState readerState,
    ReaderNotifier readerNotifier,
    AppThemeData theme,
    ReaderTheme readerTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: readerTheme.backgroundColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                    style: TextStyle(color: readerTheme.textColor.withOpacity(0.6), fontSize: 12),
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
                      activeColor: readerTheme.primaryColor,
                      inactiveColor: readerTheme.textColor.withOpacity(0.2),
                    ),
                  ),
                  Text(
                    '${readerState.chapters.length}',
                    style: TextStyle(color: readerTheme.textColor.withOpacity(0.6), fontSize: 12),
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
                    color: readerTheme.textColor,
                    onTap: _toggleChapterList,
                  ),
                  _buildMenuButton(
                    icon: Icons.settings,
                    label: '设置',
                    color: readerTheme.textColor,
                    onTap: _showReaderSettings,
                  ),
                  _buildMenuButton(
                    icon: _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                    label: '自动',
                    color: readerTheme.textColor,
                    onTap: _toggleAutoScroll,
                  ),
                  _buildMenuButton(
                    icon: _isReadingAloud ? Icons.stop : Icons.volume_up,
                    label: '朗读',
                    color: readerTheme.textColor,
                    onTap: _toggleReadAloud,
                  ),
                  _buildMenuButton(
                    icon: Icons.bookmark_border,
                    label: '书签',
                    color: readerTheme.textColor,
                    onTap: () async {
                      final readerNotifier = ref.read(readerNotifierProvider(widget.book).notifier);
                      await readerNotifier.addBookmark();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('书签已添加'),
                            backgroundColor: readerTheme.primaryColor,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
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
    ReaderTheme readerTheme,
  ) {
    return Container(
      color: readerTheme.backgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: readerTheme.textColor.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '目录 (${readerState.chapters.length})',
                  style: TextStyle(
                    color: readerTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: readerTheme.textColor),
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
                      color: isCurrent ? readerTheme.primaryColor : readerTheme.textColor,
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
    );
  }

  void _showSearchDialog() {
    final readerTheme = ReaderTheme.getThemeByIndex(_themeIndex);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: readerTheme.backgroundColor,
            title: Text(
              '搜索正文',
              style: TextStyle(color: readerTheme.textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  style: TextStyle(color: readerTheme.textColor),
                  decoration: InputDecoration(
                    hintText: '输入搜索关键词',
                    hintStyle: TextStyle(color: readerTheme.textColor.withOpacity(0.5)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: readerTheme.primaryColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: readerTheme.primaryColor),
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
                    style: TextStyle(color: readerTheme.textColor.withOpacity(0.6)),
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
                child: Text(
                  '取消',
                  style: TextStyle(color: readerTheme.textColor.withOpacity(0.6)),
                ),
              ),
              if (_searchResults.isNotEmpty) ...[
                TextButton(
                  onPressed: _previousSearchResult,
                  child: Text(
                    '上一个',
                    style: TextStyle(color: readerTheme.primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: _nextSearchResult,
                  child: Text(
                    '下一个',
                    style: TextStyle(color: readerTheme.primaryColor),
                  ),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '确定',
                  style: TextStyle(color: readerTheme.primaryColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
