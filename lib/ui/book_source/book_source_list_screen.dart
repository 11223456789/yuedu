import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../constants/strings.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import 'book_source_edit_screen.dart';
import 'book_source_debug_screen.dart';

class BookSourceListScreen extends ConsumerStatefulWidget {
  const BookSourceListScreen({super.key});

  @override
  ConsumerState<BookSourceListScreen> createState() => _BookSourceListScreenState();
}

class _BookSourceListScreenState extends ConsumerState<BookSourceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isValidating = false;
  final List<BookSourceItem> _bookSources = [];

  @override
  void initState() {
    super.initState();
    _loadMockSources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockSources() {
    _bookSources.addAll([
      BookSourceItem(
        url: 'https://www.example1.com',
        name: '笔趣阁',
        group: '默认分组',
        enabled: true,
        respondTime: 120,
      ),
      BookSourceItem(
        url: 'https://www.example2.com',
        name: '起点中文',
        group: '默认分组',
        enabled: true,
        respondTime: 85,
      ),
      BookSourceItem(
        url: 'https://www.example3.com',
        name: '纵横中文',
        group: '默认分组',
        enabled: false,
        respondTime: 200,
      ),
      BookSourceItem(
        url: 'https://www.example4.com',
        name: '17K小说',
        group: '其他分组',
        enabled: true,
        respondTime: 150,
      ),
    ]);
  }

  Future<void> _validateSources() async {
    setState(() {
      _isValidating = true;
    });

    // 模拟校验过程
    for (int i = 0; i < _bookSources.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _bookSources[i].isValidating = true;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isValidating = false;
        for (var source in _bookSources) {
          source.isValidating = false;
          source.isValid = source.respondTime < 500;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '书源管理',
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.primary),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('导入书源'),
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('导出书源'),
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: ListTile(
                  leading: Icon(Icons.qr_code),
                  title: Text('二维码扫描'),
                ),
              ),
            ],
            onSelected: (value) {
              // TODO: 实现导入/导出/扫描功能
            },
          ),
        ],
      ),
      body: Container(
        color: theme.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.onBackground),
                decoration: InputDecoration(
                  hintText: '搜索书源...',
                  hintStyle: TextStyle(color: theme.subText),
                  prefixIcon: Icon(Icons.search, color: theme.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: theme.primary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _isSearching = value.isNotEmpty;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 ${_bookSources.length} 个书源',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 13,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isValidating ? null : _validateSources,
                    icon: _isValidating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primary,
                            ),
                          )
                        : Icon(Icons.refresh, color: theme.primary),
                    label: Text(
                      _isValidating ? '校验中...' : '批量校验',
                      style: TextStyle(color: theme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const GoldDivider(),
            Expanded(
              child: _bookSources.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.source,
                            size: 64,
                            color: theme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无书源',
                            style: TextStyle(
                              color: theme.subText,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击下方按钮添加书源',
                            style: TextStyle(
                              color: theme.subText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookSources.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final source = _bookSources[index];
                        return _buildSourceItem(source, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookSourceEditScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSourceItem(BookSourceItem source, AppThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: source.isValid == false ? theme.error : theme.divider,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookSourceEditScreen(source: source),
              ),
            );
          },
          onLongPress: () {
            _showSourceOptions(context, source, theme);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        source.name,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: source.enabled,
                      onChanged: (value) {
                        setState(() {
                          source.enabled = value;
                        });
                      },
                      activeColor: theme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (source.group != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          source.group!,
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: source.respondTime < 200
                            ? Colors.green.withOpacity(0.1)
                            : source.respondTime < 500
                                ? Colors.orange.withOpacity(0.1)
                                : theme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (source.isValidating)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primary,
                              ),
                            )
                          else
                            Icon(
                              source.isValid == false
                                  ? Icons.error_outline
                                  : Icons.speed,
                              size: 12,
                              color: source.respondTime < 200
                                  ? Colors.green
                                  : source.respondTime < 500
                                      ? Colors.orange
                                      : theme.error,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            '${source.respondTime}ms',
                            style: TextStyle(
                              color: source.respondTime < 200
                                  ? Colors.green
                                  : source.respondTime < 500
                                      ? Colors.orange
                                      : theme.error,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  source.url,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSourceOptions(BuildContext context, BookSourceItem source, AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: theme.primary),
              title: Text(
                '编辑书源',
                style: TextStyle(color: theme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookSourceEditScreen(source: source),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report, color: theme.primary),
              title: Text(
                '调试书源',
                style: TextStyle(color: theme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookSourceDebugScreen(source: source),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.error),
              title: Text(
                '删除书源',
                style: TextStyle(color: theme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteSource(source);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSource(BookSourceItem source) {
    final theme = ref.read(themeNotifierProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '确认删除',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Text(
          '确定要删除书源"${source.name}"吗？',
          style: TextStyle(color: theme.subText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: theme.subText),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _bookSources.remove(source);
              });
              Navigator.pop(context);
            },
            child: Text(
              '删除',
              style: TextStyle(color: theme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class BookSourceItem {
  final String url;
  final String name;
  final String? group;
  bool enabled;
  int respondTime;
  bool? isValid;
  bool isValidating;

  BookSourceItem({
    required this.url,
    required this.name,
    this.group,
    this.enabled = true,
    this.respondTime = 0,
    this.isValid,
    this.isValidating = false,
  });
}
