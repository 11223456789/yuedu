import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../data/database/tables/books_table.dart';

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
  int _currentChapterIndex = 0;
  double _fontSize = 18;
  double _lineHeight = 1.6;
  double _autoScrollSpeed = 1.0;
  Color _backgroundColor = AppColors.darkBackground;
  Color _textColor = AppColors.textPrimary;
  String _searchQuery = '';
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;

  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      if (_isAutoScrolling && mounted) {
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

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
      _pageController.jumpToPage(_currentChapterIndex);
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex < 100) {
      setState(() {
        _currentChapterIndex++;
      });
      _pageController.jumpToPage(_currentChapterIndex);
    }
  }

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < 32) _fontSize += 2;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 12) _fontSize -= 2;
    });
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
                  decoration: InputDecoration(
                    hintText: '输入搜索关键词',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.gold),
                    ),
                    focusedBorder: const UnderlineInputBorder(
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
                    style: TextStyle(color: AppColors.textSecondary),
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

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchIndex = -1;
      });
      return;
    }
    
    final chapterContent = _getChapterContentText(_currentChapterIndex);
    final results = <int>[];
    int index = 0;
    while (true) {
      index = chapterContent.indexOf(query, index);
      if (index == -1) break;
      results.add(index);
      index += query.length;
    }
    
    setState(() {
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });
  }

  String _getChapterContentText(int index) {
    return '''这是一个示例章节内容。在实际应用中，这里会显示从书源获取到的章节正文。

佩宇书屋是一个基于 Flutter 开发的跨平台阅读应用，支持多种书源解析方式，包括 CSS 选择器、XPath、JSONPath、正则表达式和 JavaScript 脚本。

用户可以自由添加和管理书源，搜索全网书籍，享受流畅的阅读体验。

阅读界面支持多种自定义设置，包括字体大小、行间距、背景颜色等，让用户可以根据自己的喜好调整阅读环境。

鎏金主题设计，低调奢华，为用户提供舒适的阅读体验。

...''';
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
    return Scaffold(
      body: GestureDetector(
        onTap: _toggleMenu,
        child: Stack(
          children: [
            Container(
              color: _backgroundColor,
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  return _buildChapterContent(index);
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentChapterIndex = index;
                  });
                },
              ),
            ),
            if (_showMenu) _buildTopBar(),
            if (_showMenu) _buildBottomBar(),
            if (_showChapterList) _buildChapterDrawer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '第 ${_currentChapterIndex + 1} 章',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: AppColors.textPrimary),
                  onPressed: _showSearchDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_book, color: AppColors.textPrimary),
                      onPressed: _toggleChapterList,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          activeTrackColor: AppColors.gold,
                          thumbColor: AppColors.gold,
                          inactiveTrackColor: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        child: Slider(
                          value: _currentChapterIndex.toDouble(),
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            setState(() {
                              _currentChapterIndex = value.toInt();
                            });
                            _pageController.jumpToPage(_currentChapterIndex);
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: AppColors.textPrimary),
                      onPressed: _showSettingsDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomIcon(Icons.nightlight_round, '夜间', () {}),
                    _buildBottomIcon(Icons.format_size, '字体', _showFontSizeDialog),
                    _buildBottomIcon(Icons.brightness_6, '亮度', () {}),
                    _buildBottomIcon(Icons.more_vert, '更多', () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterContent(int index) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: MediaQuery.of(context).padding.top + 60,
        bottom: MediaQuery.of(context).padding.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第 ${index + 1} 章 示例章节标题',
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize + 4,
              fontWeight: FontWeight.bold,
              height: _lineHeight,
            ),
          ),
          const SizedBox(height: 24),
          _buildHighlightedText(),
        ],
      ),
    );
  }

  Widget _buildHighlightedText() {
    final text = _getChapterContentText(_currentChapterIndex);
    
    if (_searchQuery.isEmpty || _searchResults.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: _textColor,
          fontSize: _fontSize,
          height: _lineHeight,
        ),
      );
    }

    final children = <TextSpan>[];
    int currentIndex = 0;
    
    for (int i = 0; i < _searchResults.length; i++) {
      final matchIndex = _searchResults[i];
      
      if (matchIndex > currentIndex) {
        children.add(TextSpan(
          text: text.substring(currentIndex, matchIndex),
          style: TextStyle(
            color: _textColor,
            fontSize: _fontSize,
            height: _lineHeight,
          ),
        ));
      }
      
      final isCurrentMatch = i == _currentSearchIndex;
      children.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + _searchQuery.length),
        style: TextStyle(
          color: isCurrentMatch ? Colors.black : _textColor,
          fontSize: _fontSize,
          height: _lineHeight,
          backgroundColor: isCurrentMatch ? AppColors.gold : AppColors.gold.withOpacity(0.3),
        ),
      ));
      
      currentIndex = matchIndex + _searchQuery.length;
    }
    
    if (currentIndex < text.length) {
      children.add(TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(
          color: _textColor,
          fontSize: _fontSize,
          height: _lineHeight,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: children),
    );
  }

  Widget _buildChapterDrawer() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.7,
      child: Container(
        color: AppColors.darkSurface,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '目录',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: _toggleChapterList,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: 100,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentChapterIndex;
                  return ListTile(
                    title: Text(
                      '第 ${index + 1} 章',
                      style: TextStyle(
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.gold.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _currentChapterIndex = index;
                      });
                      _pageController.jumpToPage(index);
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

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '字体设置',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.textPrimary),
                      onPressed: () {
                        setDialogState(() {
                          if (_fontSize > 12) _fontSize -= 2;
                        });
                        setState(() {});
                      },
                    ),
                    Text(
                      '${_fontSize.toInt()}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.textPrimary),
                      onPressed: () {
                        setDialogState(() {
                          if (_fontSize < 32) _fontSize += 2;
                        });
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _fontSize,
                  min: 12,
                  max: 32,
                  divisions: 10,
                  activeColor: AppColors.gold,
                  thumbColor: AppColors.gold,
                  onChanged: (value) {
                    setDialogState(() {
                      _fontSize = value;
                    });
                    setState(() {});
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '确定',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  void _showScrollSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '滚动速度设置',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.textPrimary),
                      onPressed: () {
                        setDialogState(() {
                          if (_autoScrollSpeed > 0.5) _autoScrollSpeed -= 0.5;
                        });
                        setState(() {});
                      },
                    ),
                    Text(
                      '${_autoScrollSpeed.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.textPrimary),
                      onPressed: () {
                        setDialogState(() {
                          if (_autoScrollSpeed < 5.0) _autoScrollSpeed += 0.5;
                        });
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _autoScrollSpeed,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  activeColor: AppColors.gold,
                  thumbColor: AppColors.gold,
                  onChanged: (value) {
                    setDialogState(() {
                      _autoScrollSpeed = value;
                    });
                    setState(() {});
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '确定',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '阅读设置',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingItem(
                icon: Icons.format_size,
                title: '字体大小',
                subtitle: '${_fontSize.toInt()}sp',
                onTap: _showFontSizeDialog,
              ),
              _buildSettingItem(
                icon: Icons.format_line_spacing,
                title: '行间距',
                subtitle: '${_lineHeight.toStringAsFixed(1)}x',
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.palette,
                title: '阅读背景',
                subtitle: '深色',
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.play_arrow,
                title: '自动滚动',
                subtitle: _isAutoScrolling ? '正在滚动' : '关闭',
                onTap: () {
                  Navigator.pop(context);
                  _toggleAutoScroll();
                },
              ),
              _buildSettingItem(
                icon: Icons.speed,
                title: '滚动速度',
                subtitle: '${_autoScrollSpeed.toStringAsFixed(1)}x',
                onTap: () {
                  Navigator.pop(context);
                  _showScrollSpeedDialog();
                },
              ),
              _buildSettingItem(
                icon: Icons.volume_up,
                title: '朗读设置',
                subtitle: '未设置',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
