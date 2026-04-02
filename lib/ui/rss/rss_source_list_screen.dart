import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../data/database/daos/rss_source_dao.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import 'rss_article_list_screen.dart';
import 'rss_source_edit_screen.dart';

class RssSourceListScreen extends ConsumerStatefulWidget {
  const RssSourceListScreen({super.key});

  @override
  ConsumerState<RssSourceListScreen> createState() => _RssSourceListScreenState();
}

class _RssSourceListScreenState extends ConsumerState<RssSourceListScreen> {
  final RssSourceDao _dao = RssSourceDao();
  List<RssSource> _sources = [];
  bool _isLoading = true;
  bool _isSelecting = false;
  final Set<String> _selectedSources = {};

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() {
      _isLoading = true;
    });
    final sources = await _dao.getAllSources();
    setState(() {
      _sources = sources;
      _isLoading = false;
    });
  }

  Future<void> _importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      final content = await File(file.path!).readAsString();
      final List<dynamic> list = jsonDecode(content);
      
      int count = 0;
      for (final item in list) {
        if (item is Map) {
          final source = RssSource.fromJson(Map<String, dynamic>.from(item));
          await _dao.insertOrUpdateSource(source);
          count++;
        }
      }

      await _loadSources();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 $count 个RSS源')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _exportToJson() async {
    try {
      final list = _sources.map((s) => s.toJson()).toList();
      final json = jsonEncode(list);
      
      await Share.share(
        json,
        subject: 'RSS源备份',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  void _toggleSelection(String url) {
    setState(() {
      if (_selectedSources.contains(url)) {
        _selectedSources.remove(url);
      } else {
        _selectedSources.add(url);
      }
      if (_selectedSources.isEmpty) {
        _isSelecting = false;
      }
    });
  }

  Future<void> _deleteSelected() async {
    for (final url in _selectedSources) {
      await _dao.deleteSource(url);
    }
    setState(() {
      _selectedSources.clear();
      _isSelecting = false;
    });
    await _loadSources();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: 'RSS订阅',
        actions: [
          if (_isSelecting) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isSelecting = false;
                  _selectedSources.clear();
                });
              },
              child: Text('取消', style: TextStyle(color: theme.primary)),
            ),
            TextButton(
              onPressed: _deleteSelected,
              child: Text('删除(${_selectedSources.length})', style: TextStyle(color: theme.error)),
            ),
          ] else ...[
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.primary),
              onSelected: (value) {
                switch (value) {
                  case 'import':
                    _importFromJson();
                    break;
                  case 'export':
                    _exportToJson();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.file_upload),
                      SizedBox(width: 8),
                      Text('导入RSS源'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download),
                      SizedBox(width: 8),
                      Text('导出RSS源'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : _sources.isEmpty
              ? _buildEmptyView(theme)
              : _buildSourceList(theme),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RssSourceEditScreen(),
            ),
          ).then((_) => _loadSources());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed, size: 64, color: theme.subText),
          const SizedBox(height: 16),
          Text(
            '暂无RSS订阅',
            style: TextStyle(color: theme.subText, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角添加RSS源',
            style: TextStyle(color: theme.subText.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceList(AppThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _sources.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final source = _sources[index];
        final isSelected = _selectedSources.contains(source.sourceUrl);
        
        return Card(
          color: theme.surface,
          child: InkWell(
            onTap: () {
              if (_isSelecting) {
                _toggleSelection(source.sourceUrl);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RssArticleListScreen(source: source),
                  ),
                );
              }
            },
            onLongPress: () {
              setState(() {
                _isSelecting = true;
                _selectedSources.add(source.sourceUrl);
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_isSelecting)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? theme.primary : theme.subText,
                      ),
                    ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.rss_feed, color: theme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.sourceName,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (source.sourceGroup != null)
                          Text(
                            source.sourceGroup!,
                            style: TextStyle(
                              color: theme.subText,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          source.sourceUrl,
                          style: TextStyle(
                            color: theme.subText,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: source.enabled,
                    onChanged: (value) async {
                      await _dao.toggleEnabled(source.sourceUrl, value);
                      await _loadSources();
                    },
                    activeColor: theme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
