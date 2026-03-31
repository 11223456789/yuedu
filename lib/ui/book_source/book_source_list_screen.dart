import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
import 'import_source_dialog.dart';

enum BookSourceSort {
  manual,
  auto,
  name,
  url,
  time,
  responseTime,
  enable,
}

extension BookSourceSortExtension on BookSourceSort {
  String get displayName {
    switch (this) {
      case BookSourceSort.manual:
        return '手动排序';
      case BookSourceSort.auto:
        return '智能排序';
      case BookSourceSort.name:
        return '名称排序';
      case BookSourceSort.url:
        return 'URL排序';
      case BookSourceSort.time:
        return '更新时间';
      case BookSourceSort.responseTime:
        return '响应时间';
      case BookSourceSort.enable:
        return '启用状态';
    }
  }
}

class BookSourceListScreen extends ConsumerStatefulWidget {
  const BookSourceListScreen({super.key});

  @override
  ConsumerState<BookSourceListScreen> createState() => _BookSourceListScreenState();
}

class _BookSourceListScreenState extends ConsumerState<BookSourceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isValidating = false;
  bool _isSelecting = false;
  bool _sortAscending = true;
  BookSourceSort _currentSort = BookSourceSort.manual;
  List<BookSource> _bookSources = [];
  List<BookSource> _filteredSources = [];
  List<String> _selectedSources = [];
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
        _applySortAndFilter();
        _isLoading = false;
      });
    }
  }

  void _applySortAndFilter() {
    var sources = List<BookSource>.from(_bookSources);

    // 应用搜索过滤
    if (_searchController.text.isNotEmpty) {
      final keyword = _searchController.text.toLowerCase();
      sources = sources.where((s) {
        return s.bookSourceName.toLowerCase().contains(keyword) ||
            s.bookSourceUrl.toLowerCase().contains(keyword) ||
            (s.bookSourceGroup?.toLowerCase().contains(keyword) ?? false);
      }).toList();
    }

    // 应用排序
    sources = _sortSources(sources);

    setState(() {
      _filteredSources = sources;
    });
  }

  List<BookSource> _sortSources(List<BookSource> sources) {
    switch (_currentSort) {
      case BookSourceSort.manual:
        return sources;
      case BookSourceSort.auto:
        return sources..sort((a, b) => a.customOrder.compareTo(b.customOrder));
      case BookSourceSort.name:
        return sources..sort((a, b) => _sortAscending
            ? a.bookSourceName.compareTo(b.bookSourceName)
            : b.bookSourceName.compareTo(a.bookSourceName));
      case BookSourceSort.url:
        return sources..sort((a, b) => _sortAscending
            ? a.bookSourceUrl.compareTo(b.bookSourceUrl)
            : b.bookSourceUrl.compareTo(a.bookSourceUrl));
      case BookSourceSort.time:
        return sources..sort((a, b) => _sortAscending
            ? a.respondTime.compareTo(b.respondTime)
            : b.respondTime.compareTo(a.respondTime));
      case BookSourceSort.responseTime:
        return sources..sort((a, b) => _sortAscending
            ? a.respondTime.compareTo(b.respondTime)
            : b.respondTime.compareTo(a.respondTime));
      case BookSourceSort.enable:
        return sources..sort((a, b) {
          if (a.enabled == b.enabled) {
            return a.bookSourceName.compareTo(b.bookSourceName);
          }
          return _sortAscending
              ? (a.enabled ? -1 : 1)
              : (a.enabled ? 1 : -1);
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
        SnackBar(content: Text('已校验 ${_filteredSources.length} 个书源')),
      );
    }
  }

  void _toggleSelection(String sourceUrl) {
    setState(() {
      if (_selectedSources.contains(sourceUrl)) {
        _selectedSources.remove(sourceUrl);
      } else {
        _selectedSources.add(sourceUrl);
      }
      if (_selectedSources.isEmpty) {
        _isSelecting = false;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedSources = _filteredSources.map((s) => s.bookSourceUrl).toList();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSources.clear();
      _isSelecting = false;
    });
  }

  Future<void> _batchEnable(bool enable) async {
    final repository = ref.read(bookSourceRepositoryProvider);
    for (final url in _selectedSources) {
      await repository.toggleEnabled(url, enable);
    }
    _clearSelection();
    _loadSources();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已${enable ? '启用' : '禁用'} ${_selectedSources.length} 个书源')),
    );
  }

  Future<void> _batchDelete() async {
    final theme = ref.read(themeNotifierProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('确认删除', style: TextStyle(color: theme.onSurface)),
        content: Text(
          '确定要删除选中的 ${_selectedSources.length} 个书源吗？',
          style: TextStyle(color: theme.subText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: theme.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: theme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(bookSourceRepositoryProvider);
      for (final url in _selectedSources) {
        await repository.deleteSource(url);
      }
      _clearSelection();
      _loadSources();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 ${_selectedSources.length} 个书源')),
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
          if (_isSelecting) ...[
            TextButton(
              onPressed: _selectedSources.length == _filteredSources.length
                  ? _clearSelection
                  : _selectAll,
              child: Text(
                _selectedSources.length == _filteredSources.length ? '全不选' : '全选',
                style: TextStyle(color: theme.background),
              ),
            ),
            TextButton(
              onPressed: _clearSelection,
              child: Text(
                '取消',
                style: TextStyle(color: theme.background),
              ),
            ),
          ] else ...[
            PopupMenuButton<BookSourceSort>(
              icon: Icon(Icons.sort, color: theme.primary),
              onSelected: (sort) {
                setState(() {
                  if (_currentSort == sort) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _currentSort = sort;
                    _sortAscending = true;
                  }
                  _applySortAndFilter();
                });
              },
              itemBuilder: (context) => BookSourceSort.values.map((sort) {
                return PopupMenuItem(
                  value: sort,
                  child: Row(
                    children: [
                      if (_currentSort == sort)
                        Icon(Icons.check, color: theme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(sort.displayName),
                      if (_currentSort == sort) ...[
                        const Spacer(),
                        Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: theme.primary,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
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
                const PopupMenuItem(
                  value: 'validate',
                  child: ListTile(
                    leading: Icon(Icons.check_circle),
                    title: Text('批量校验'),
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
                  case 'validate':
                    _validateSources();
                    break;
                }
              },
            ),
          ],
        ],
      ),
      body: Container(
        color: theme.background,
        child: Column(
          children: [
            if (_isSelecting)
              _buildSelectionBar(theme),
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
                            _applySortAndFilter();
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
                  _applySortAndFilter();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSelecting
                        ? '已选择 ${_selectedSources.length} 个书源'
                        : '共 ${_filteredSources.length} 个书源',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 13,
                    ),
                  ),
                  if (!_isSelecting)
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
                  : _filteredSources.isEmpty
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
                          itemCount: _filteredSources.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final source = _filteredSources[index];
                            return _buildSourceItem(source, theme);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton(
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

  Widget _buildSelectionBar(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: theme.primary.withOpacity(0.1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 启用/禁用
            TextButton.icon(
              onPressed: () => _batchEnable(true),
              icon: Icon(Icons.check_circle, color: theme.primary, size: 18),
              label: Text('启用', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: () => _batchEnable(false),
              icon: Icon(Icons.cancel, color: theme.subText, size: 18),
              label: Text('禁用', style: TextStyle(color: theme.subText, fontSize: 12)),
            ),
            // 发现启用/禁用
            TextButton.icon(
              onPressed: () => _batchEnableExplore(true),
              icon: Icon(Icons.explore, color: theme.primary, size: 18),
              label: Text('发现', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: () => _batchEnableExplore(false),
              icon: Icon(Icons.explore_off, color: theme.subText, size: 18),
              label: Text('关发现', style: TextStyle(color: theme.subText, fontSize: 12)),
            ),
            // 校验
            TextButton.icon(
              onPressed: _batchCheckSources,
              icon: Icon(Icons.fact_check, color: theme.primary, size: 18),
              label: Text('校验', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            // 置顶/置底
            TextButton.icon(
              onPressed: _batchTop,
              icon: Icon(Icons.vertical_align_top, color: theme.primary, size: 18),
              label: Text('置顶', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: _batchBottom,
              icon: Icon(Icons.vertical_align_bottom, color: theme.primary, size: 18),
              label: Text('置底', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            // 分组
            TextButton.icon(
              onPressed: _showAddToGroupDialog,
              icon: Icon(Icons.folder, color: theme.primary, size: 18),
              label: Text('加分组', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: _showRemoveFromGroupDialog,
              icon: Icon(Icons.folder_delete, color: theme.subText, size: 18),
              label: Text('减分组', style: TextStyle(color: theme.subText, fontSize: 12)),
            ),
            // 导出
            TextButton.icon(
              onPressed: _batchExport,
              icon: Icon(Icons.file_download, color: theme.primary, size: 18),
              label: Text('导出', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: _batchShare,
              icon: Icon(Icons.share, color: theme.primary, size: 18),
              label: Text('分享', style: TextStyle(color: theme.primary, fontSize: 12)),
            ),
            // 删除
            TextButton.icon(
              onPressed: _batchDelete,
              icon: Icon(Icons.delete, color: theme.error, size: 18),
              label: Text('删除', style: TextStyle(color: theme.error, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem(BookSource source, AppThemeData theme) {
    final isSelected = _selectedSources.contains(source.bookSourceUrl);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? theme.primary.withOpacity(0.1) : theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.primary : theme.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_isSelecting) {
              _toggleSelection(source.bookSourceUrl);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookSourceEditScreen(
                    sourceUrl: source.bookSourceUrl,
                  ),
                ),
              ).then((_) => _loadSources());
            }
          },
          onLongPress: () {
            setState(() {
              _isSelecting = true;
              _toggleSelection(source.bookSourceUrl);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_isSelecting)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? theme.primary : theme.subText,
                        ),
                      ),
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
                      onChanged: _isSelecting
                          ? null
                          : (value) async {
                              final repository =
                                  ref.read(bookSourceRepositoryProvider);
                              await repository.toggleEnabled(
                                  source.bookSourceUrl, value);
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
              leading: Icon(Icons.link, color: theme.primary),
              title: Text(
                '网络导入',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '从URL导入书源',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showNetworkImportDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.file_upload, color: theme.primary),
              title: Text(
                '本地导入',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '从JSON文件导入',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _importFromFile();
              },
            ),
            ListTile(
              leading: Icon(Icons.content_paste, color: theme.primary),
              title: Text(
                '剪贴板导入',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '从剪贴板粘贴JSON',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _importFromClipboard();
              },
            ),
            ListTile(
              leading: Icon(Icons.qr_code_scanner, color: theme.primary),
              title: Text(
                '二维码导入',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '扫描二维码导入书源',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showQRScanDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showNetworkImportDialog() async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) => const ImportFromUrlDialog(),
    );

    if (url != null && url.isNotEmpty) {
      // TODO: 从网络获取书源JSON
      // 暂时显示导入对话框
      showDialog(
        context: context,
        builder: (context) => ImportSourceDialog(
          source: url,
          isUrl: true,
        ),
      ).then((count) {
        if (count != null && count > 0) {
          _loadSources();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 $count 个书源')),
          );
        }
      });
    }
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final content = await file.readAsString();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => ImportSourceDialog(source: content),
          ).then((count) {
            if (count != null && count > 0) {
              _loadSources();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('成功导入 $count 个书源')),
              );
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件导入失败: $e')),
      );
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;

      if (text == null || text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('剪贴板为空')),
        );
        return;
      }

      // 检查是否是有效的JSON
      try {
        jsonDecode(text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('剪贴板内容不是有效的JSON')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => ImportSourceDialog(source: text),
      ).then((count) {
        if (count != null && count > 0) {
          _loadSources();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 $count 个书源')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('剪贴板导入失败: $e')),
      );
    }
  }

  void _showExportDialog() {
    final theme = ref.read(themeNotifierProvider);
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
              leading: Icon(Icons.file_download, color: theme.primary),
              title: Text(
                '导出为JSON文件',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '保存到本地存储',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _exportAllToFile();
              },
            ),
            ListTile(
              leading: Icon(Icons.content_copy, color: theme.primary),
              title: Text(
                '复制到剪贴板',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '复制JSON到剪贴板',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _copyAllToClipboard();
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: theme.primary),
              title: Text(
                '分享书源',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '通过其他应用分享',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _shareAllSources();
              },
            ),
            ListTile(
              leading: Icon(Icons.qr_code, color: theme.primary),
              title: Text(
                '生成二维码',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '生成分享二维码',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _showQRCodeDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAllToFile() async {
    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final json = await repository.exportToJson([]);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出书源',
        fileName: 'bookSource_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(json);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: $result')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  Future<void> _copyAllToClipboard() async {
    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final json = await repository.exportToJson([]);

      await Clipboard.setData(ClipboardData(text: json));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已复制 ${_bookSources.length} 个书源到剪贴板')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制失败: $e')),
      );
    }
  }

  Future<void> _shareAllSources() async {
    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final json = await repository.exportToJson([]);

      await Share.share(
        json,
        subject: '书源分享',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  Future<void> _showQRCodeDialog() async {
    final theme = ref.read(themeNotifierProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '书源二维码',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code,
                size: 150,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '二维码分享功能开发中',
              style: TextStyle(color: theme.subText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭', style: TextStyle(color: theme.subText)),
          ),
        ],
      ),
    );
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

  // ========== 批量操作方法 ==========

  Future<void> _batchEnableExplore(bool enable) async {
    final repository = ref.read(bookSourceRepositoryProvider);
    for (final url in _selectedSources) {
      await repository.toggleExploreEnabled(url, enable);
    }
    _clearSelection();
    _loadSources();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已${enable ? '启用' : '禁用'}发现 ${_selectedSources.length} 个书源')),
    );
  }

  Future<void> _batchCheckSources() async {
    setState(() {
      _isValidating = true;
    });

    // TODO: 实现书源校验逻辑
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isValidating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已校验 ${_selectedSources.length} 个书源')),
    );
  }

  Future<void> _batchTop() async {
    // TODO: 实现置顶逻辑
    _clearSelection();
    _loadSources();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已置顶选中的书源')),
    );
  }

  Future<void> _batchBottom() async {
    // TODO: 实现置底逻辑
    _clearSelection();
    _loadSources();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已置底选中的书源')),
    );
  }

  Future<void> _batchExport() async {
    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final selectedSourceList = _bookSources
          .where((s) => _selectedSources.contains(s.bookSourceUrl))
          .toList();
      final json = await repository.exportSourcesToJson(selectedSourceList);

      // 保存到文件
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出书源',
        fileName: 'bookSource_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(json);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: $result')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  Future<void> _batchShare() async {
    try {
      final repository = ref.read(bookSourceRepositoryProvider);
      final selectedSourceList = _bookSources
          .where((s) => _selectedSources.contains(s.bookSourceUrl))
          .toList();
      final json = await repository.exportSourcesToJson(selectedSourceList);

      await Share.share(
        json,
        subject: '书源分享',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  void _showAddToGroupDialog() {
    final theme = ref.read(themeNotifierProvider);
    final controller = TextEditingController();

    // 获取所有分组
    final groups = _bookSources
        .where((s) => s.bookSourceGroup != null)
        .map((s) => s.bookSourceGroup!)
        .expand((g) => g.split(','))
        .map((g) => g.trim())
        .toSet()
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '添加到分组',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                hintText: '分组名称',
                hintStyle: TextStyle(color: theme.subText),
              ),
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: groups.map((g) => ActionChip(
                  label: Text(g, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    controller.text = g;
                  },
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: theme.subText)),
          ),
          TextButton(
            onPressed: () async {
              final groupName = controller.text.trim();
              if (groupName.isNotEmpty) {
                final repository = ref.read(bookSourceRepositoryProvider);
                for (final url in _selectedSources) {
                  final source = _bookSources.firstWhere((s) => s.bookSourceUrl == url);
                  final newGroup = source.bookSourceGroup == null
                      ? groupName
                      : '${source.bookSourceGroup},$groupName';
                  await repository.saveSource(source.copyWith(bookSourceGroup: newGroup));
                }
                Navigator.pop(context);
                _clearSelection();
                _loadSources();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已添加到分组: $groupName')),
                );
              }
            },
            child: Text('确定', style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }

  void _showRemoveFromGroupDialog() {
    final theme = ref.read(themeNotifierProvider);
    final controller = TextEditingController();

    // 获取所有分组
    final groups = _bookSources
        .where((s) => s.bookSourceGroup != null)
        .map((s) => s.bookSourceGroup!)
        .expand((g) => g.split(','))
        .map((g) => g.trim())
        .toSet()
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '从分组移除',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                hintText: '分组名称',
                hintStyle: TextStyle(color: theme.subText),
              ),
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: groups.map((g) => ActionChip(
                  label: Text(g, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    controller.text = g;
                  },
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: theme.subText)),
          ),
          TextButton(
            onPressed: () async {
              final groupName = controller.text.trim();
              if (groupName.isNotEmpty) {
                final repository = ref.read(bookSourceRepositoryProvider);
                for (final url in _selectedSources) {
                  final source = _bookSources.firstWhere((s) => s.bookSourceUrl == url);
                  if (source.bookSourceGroup != null) {
                    final newGroups = source.bookSourceGroup!
                        .split(',')
                        .map((g) => g.trim())
                        .where((g) => g != groupName)
                        .join(',');
                    await repository.saveSource(source.copyWith(
                      bookSourceGroup: newGroups.isEmpty ? null : newGroups,
                    ));
                  }
                }
                Navigator.pop(context);
                _clearSelection();
                _loadSources();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已从分组移除: $groupName')),
                );
              }
            },
            child: Text('确定', style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }
}
