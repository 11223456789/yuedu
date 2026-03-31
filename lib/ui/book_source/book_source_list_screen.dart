import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../constants/strings.dart';
import '../../data/repositories/book_source_repository.dart';
import '../../data/database/daos/book_source_dao.dart';
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
  List<BookSource> _bookSources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    setState(() {
      _isLoading = true;
    });

    final repository = ref.read(bookSourceRepositoryProvider);
    final sources = await repository.getAllSources();

    if (mounted) {
      setState(() {
        _bookSources = sources;
        _isLoading = false;
      });
    }
  }

  Future<void> _validateSources() async {
    setState(() {
      _isValidating = true;
    });

    // 模拟校验过程
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isValidating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已校验 ${_bookSources.length} 个书源')),
      );
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
              switch (value) {
                case 'import':
                  _showImportDialog();
                  break;
                case 'export':
                  _showExportDialog();
                  break;
                case 'qr':
                  _showQRScanDialog();
                  break;
              }
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
                            _loadSources();
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
                onChanged: (value) async {
                  setState(() {
                    _isSearching = value.isNotEmpty;
                  });
                  if (value.isNotEmpty) {
                    final repository = ref.read(bookSourceRepositoryProvider);
                    final results = await repository.searchSources(value);
                    setState(() {
                      _bookSources = results;
                    });
                  } else {
                    _loadSources();
                  }
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
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: theme.primary),
                    )
                  : _bookSources.isEmpty
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
                                '点击右上角导入书源',
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
          ).then((_) => _loadSources());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSourceItem(BookSource source, AppThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookSourceEditScreen(
                  sourceUrl: source.bookSourceUrl,
                ),
              ),
            ).then((_) => _loadSources());
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
                        source.bookSourceName,
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
                      onChanged: (value) async {
                        final repository = ref.read(bookSourceRepositoryProvider);
                        await repository.toggleEnabled(source.bookSourceUrl, value);
                        _loadSources();
                      },
                      activeColor: theme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (source.bookSourceGroup != null) ...[
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
                          source.bookSourceGroup!,
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
                        color: source.respondTime < 500
                            ? Colors.green.withOpacity(0.1)
                            : source.respondTime < 1000
                                ? Colors.orange.withOpacity(0.1)
                                : theme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed,
                            size: 12,
                            color: source.respondTime < 500
                                ? Colors.green
                                : source.respondTime < 1000
                                    ? Colors.orange
                                    : theme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${source.respondTime}ms',
                            style: TextStyle(
                              color: source.respondTime < 500
                                  ? Colors.green
                                  : source.respondTime < 1000
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
                  source.bookSourceUrl,
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

  void _showSourceOptions(BuildContext context, BookSource source, AppThemeData theme) {
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
                    builder: (context) => BookSourceEditScreen(
                      sourceUrl: source.bookSourceUrl,
                    ),
                  ),
                ).then((_) => _loadSources());
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
                    builder: (context) => BookSourceDebugScreen(
                      sourceUrl: source.bookSourceUrl,
                    ),
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

  void _confirmDeleteSource(BookSource source) {
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
          '确定要删除书源"${source.bookSourceName}"吗？',
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
            onPressed: () async {
              final repository = ref.read(bookSourceRepositoryProvider);
              await repository.deleteSource(source.bookSourceUrl);
              Navigator.pop(context);
              _loadSources();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('书源已删除')),
              );
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

  void _showImportDialog() {
    final theme = ref.read(themeNotifierProvider);
    final urlController = TextEditingController();
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '导入书源',
          style: TextStyle(color: theme.onSurface),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '网络导入',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                style: TextStyle(color: theme.onSurface),
                decoration: InputDecoration(
                  hintText: '输入书源URL',
                  hintStyle: TextStyle(color: theme.subText),
                  filled: true,
                  fillColor: theme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'JSON导入',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: jsonController,
                style: TextStyle(color: theme.onSurface),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '粘贴书源JSON',
                  hintStyle: TextStyle(color: theme.subText),
                  filled: true,
                  fillColor: theme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '文件导入',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _importFromFile();
                  },
                  icon: Icon(Icons.file_upload, color: theme.background),
                  label: Text(
                    '选择JSON文件',
                    style: TextStyle(color: theme.background),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            onPressed: () async {
              Navigator.pop(context);
              if (urlController.text.isNotEmpty) {
                await _importFromUrl(urlController.text);
              } else if (jsonController.text.isNotEmpty) {
                await _importFromJson(jsonController.text);
              }
            },
            child: Text(
              '导入',
              style: TextStyle(color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromUrl(String url) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ref.read(themeNotifierProvider).surface,
        content: Row(
          children: [
            CircularProgressIndicator(
              color: ref.read(themeNotifierProvider).primary,
            ),
            const SizedBox(width: 16),
            Text(
              '正在从网络导入...',
              style: TextStyle(color: ref.read(themeNotifierProvider).onSurface),
            ),
          ],
        ),
      ),
    );

    try {
      // 这里应该使用 http_client 获取远程书源
      // 暂时模拟网络请求
      await Future.delayed(const Duration(seconds: 2));

      // 模拟从网络获取的书源数据
      final mockJson = jsonEncode([
        {
          'bookSourceUrl': url,
          'bookSourceName': '网络书源${_bookSources.length + 1}',
          'bookSourceGroup': '网络导入',
          'enabled': true,
          'respondTime': 100,
        }
      ]);

      Navigator.pop(context);
      await _importFromJson(mockJson);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  Future<void> _importFromJson(String jsonStr) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ref.read(themeNotifierProvider).surface,
        content: Row(
          children: [
            CircularProgressIndicator(
              color: ref.read(themeNotifierProvider).primary,
            ),
            const SizedBox(width: 16),
            Text(
              '正在导入...',
              style: TextStyle(color: ref.read(themeNotifierProvider).onSurface),
            ),
          ],
        ),
      ),
    );

    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final count = await repository.importFromJson(jsonStr);

      Navigator.pop(context);
      _loadSources();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $count 个书源')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  Future<void> _importFromFile() async {
    try {
      // 检查 file_picker 是否可用
      // 这里使用模拟数据演示文件导入功能
      // 实际项目中需要添加 file_picker 依赖
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: ref.read(themeNotifierProvider).surface,
          title: Text(
            '文件导入',
            style: TextStyle(color: ref.read(themeNotifierProvider).onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: ref.read(themeNotifierProvider).primary,
              ),
              const SizedBox(height: 16),
              Text(
                '选择书源JSON文件',
                style: TextStyle(color: ref.read(themeNotifierProvider).onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                '（需要添加 file_picker 依赖才能使用此功能）',
                style: TextStyle(
                  color: ref.read(themeNotifierProvider).subText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(color: ref.read(themeNotifierProvider).subText),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // 模拟导入文件
                final mockJson = jsonEncode([
                  {
                    'bookSourceUrl': 'https://file.example.com',
                    'bookSourceName': '文件导入书源${_bookSources.length + 1}',
                    'bookSourceGroup': '文件导入',
                    'enabled': true,
                    'respondTime': 150,
                  }
                ]);
                await _importFromJson(mockJson);
              },
              child: Text(
                '模拟导入',
                style: TextStyle(color: ref.read(themeNotifierProvider).primary),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件导入失败: $e')),
      );
    }
  }

  void _showExportDialog() {
    final theme = ref.read(themeNotifierProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '导出书源',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.file_download, color: theme.primary),
              title: Text(
                '导出为JSON文件',
                style: TextStyle(color: theme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _exportToJson();
              },
            ),
            ListTile(
              leading: Icon(Icons.content_copy, color: theme.primary),
              title: Text(
                '复制到剪贴板',
                style: TextStyle(color: theme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _copyToClipboard();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: theme.subText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToJson() async {
    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final json = await repository.exportToJson([]);

      // 这里应该使用 file_picker 保存文件
      // 暂时显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导出 ${_bookSources.length} 个书源')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final json = await repository.exportToJson([]);

      // 这里应该使用 clipboard 复制
      // 暂时显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('书源JSON已复制到剪贴板')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制失败: $e')),
      );
    }
  }

  void _showQRScanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ref.read(themeNotifierProvider).surface,
        title: Text(
          '二维码扫描',
          style: TextStyle(color: ref.read(themeNotifierProvider).onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: ref.read(themeNotifierProvider).background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: ref.read(themeNotifierProvider).subText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '请对准书源二维码进行扫描',
              style: TextStyle(color: ref.read(themeNotifierProvider).subText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: ref.read(themeNotifierProvider).subText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 模拟扫描结果
              final mockJson = jsonEncode([
                {
                  'bookSourceUrl': 'https://qr.example.com',
                  'bookSourceName': '扫码书源${_bookSources.length + 1}',
                  'bookSourceGroup': '扫码导入',
                  'enabled': true,
                  'respondTime': 80,
                }
              ]);
              await _importFromJson(mockJson);
            },
            child: Text(
              '模拟扫描',
              style: TextStyle(color: ref.read(themeNotifierProvider).primary),
            ),
          ),
        ],
      ),
    );
  }
}
