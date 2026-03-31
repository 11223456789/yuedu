import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/daos/book_source_dao.dart';
import '../../data/repositories/book_source_repository.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

/// 书源导入对话框 - 复刻legado的ImportBookSourceDialog
class ImportSourceDialog extends ConsumerStatefulWidget {
  final String source;
  final bool isUrl;

  const ImportSourceDialog({
    super.key,
    required this.source,
    this.isUrl = false,
  });

  @override
  ConsumerState<ImportSourceDialog> createState() => _ImportSourceDialogState();
}

class _ImportSourceDialogState extends ConsumerState<ImportSourceDialog> {
  bool _isLoading = true;
  String? _error;
  List<BookSource> _allSources = [];
  List<bool> _selectStatus = [];
  List<bool> _isNewSource = [];
  List<bool> _isUpdateSource = [];
  final Map<String, BookSource> _existingSources = {};

  // 导入选项
  bool _keepOriginalName = true;
  bool _keepGroup = true;
  bool _keepEnable = true;
  String? _customGroup;
  bool _isAddGroup = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSources();
  }

  Future<void> _loadExistingSources() async {
    final repository = ref.read(bookSourceRepositoryProvider);
    final sources = await repository.getAllSources();
    for (final s in sources) {
      _existingSources[s.bookSourceUrl] = s;
    }
    _parseSource();
  }

  Future<void> _parseSource() async {
    try {
      String jsonStr;

      if (widget.isUrl) {
        // 从网络获取
        // TODO: 实现网络请求获取书源
        jsonStr = widget.source;
      } else {
        jsonStr = widget.source;
      }

      // 解析JSON
      final dynamic decoded = jsonDecode(jsonStr);
      List<Map<String, dynamic>> sourceList = [];

      if (decoded is List) {
        sourceList = decoded.cast<Map<String, dynamic>>();
      } else if (decoded is Map) {
        sourceList = [decoded.cast<String, dynamic>()];
      }

      _allSources = sourceList.map((m) => BookSource(
        bookSourceUrl: m['bookSourceUrl'] as String? ?? '',
        bookSourceName: m['bookSourceName'] as String? ?? '未命名书源',
        bookSourceGroup: m['bookSourceGroup'] as String?,
        bookSourceType: m['bookSourceType'] as int? ?? 0,
        bookUrlPattern: m['bookUrlPattern'] as String?,
        customOrder: m['customOrder'] as int? ?? 0,
        enabled: m['enabled'] as bool? ?? true,
        enabledExplore: m['enabledExplore'] as bool? ?? true,
        jsLib: m['jsLib'] as String?,
        concurrentRate: m['concurrentRate'] as String?,
        header: m['header'] as String?,
        loginUrl: m['loginUrl'] as String?,
        loginUi: m['loginUi'] as String?,
        loginCheckJs: m['loginCheckJs'] as String?,
        bookSourceComment: m['bookSourceComment'] as String?,
        exploreUrl: m['exploreUrl'] as String?,
        searchUrl: m['searchUrl'] as String?,
        ruleExplore: m['ruleExplore'] is Map ? jsonEncode(m['ruleExplore']) : m['ruleExplore'] as String?,
        ruleSearch: m['ruleSearch'] is Map ? jsonEncode(m['ruleSearch']) : m['ruleSearch'] as String?,
        ruleBookInfo: m['ruleBookInfo'] is Map ? jsonEncode(m['ruleBookInfo']) : m['ruleBookInfo'] as String?,
        ruleToc: m['ruleToc'] is Map ? jsonEncode(m['ruleToc']) : m['ruleToc'] as String?,
        ruleContent: m['ruleContent'] is Map ? jsonEncode(m['ruleContent']) : m['ruleContent'] as String?,
        respondTime: m['respondTime'] as int? ?? 100,
        lastUpdateTime: m['lastUpdateTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      )).toList();

      // 过滤掉URL为空的书源
      _allSources = _allSources.where((s) => s.bookSourceUrl.isNotEmpty).toList();

      _selectStatus = List.filled(_allSources.length, true);
      _isNewSource = List.filled(_allSources.length, false);
      _isUpdateSource = List.filled(_allSources.length, false);

      // 检查哪些是新书源，哪些是更新
      for (int i = 0; i < _allSources.length; i++) {
        final source = _allSources[i];
        final existing = _existingSources[source.bookSourceUrl];
        if (existing == null) {
          _isNewSource[i] = true;
        } else if (source.lastUpdateTime > existing.lastUpdateTime) {
          _isUpdateSource[i] = true;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '解析失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importSelected() async {
    final repository = ref.read(bookSourceRepositoryProvider);
    int importedCount = 0;

    for (int i = 0; i < _allSources.length; i++) {
      if (_selectStatus[i]) {
        var source = _allSources[i];
        final existing = _existingSources[source.bookSourceUrl];

        // 应用导入选项
        if (existing != null) {
          if (_keepOriginalName) {
            source = source.copyWith(bookSourceName: existing.bookSourceName);
          }
          if (_keepGroup && existing.bookSourceGroup != null) {
            source = source.copyWith(bookSourceGroup: existing.bookSourceGroup);
          }
          if (_keepEnable) {
            source = source.copyWith(enabled: existing.enabled);
          }
        }

        // 应用自定义分组
        if (_customGroup != null && _customGroup!.isNotEmpty) {
          if (_isAddGroup && source.bookSourceGroup != null) {
            source = source.copyWith(
              bookSourceGroup: '${source.bookSourceGroup},$_customGroup',
            );
          } else {
            source = source.copyWith(bookSourceGroup: _customGroup);
          }
        }

        await repository.saveSource(source);
        importedCount++;
      }
    }

    if (mounted) {
      Navigator.pop(context, importedCount);
    }
  }

  void _selectAll(bool select) {
    setState(() {
      for (int i = 0; i < _selectStatus.length; i++) {
        _selectStatus[i] = select;
      }
    });
  }

  void _selectNewSources() {
    setState(() {
      for (int i = 0; i < _selectStatus.length; i++) {
        _selectStatus[i] = _isNewSource[i];
      }
    });
  }

  void _selectUpdateSources() {
    setState(() {
      for (int i = 0; i < _selectStatus.length; i++) {
        _selectStatus[i] = _isUpdateSource[i];
      }
    });
  }

  int get _selectedCount => _selectStatus.where((s) => s).length;
  bool get _isSelectAll => _selectedCount == _allSources.length;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return AlertDialog(
      backgroundColor: theme.surface,
      title: Row(
        children: [
          Expanded(
            child: Text(
              '导入书源',
              style: TextStyle(color: theme.onSurface),
            ),
          ),
          if (!_isLoading && _error == null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.primary),
              onSelected: (value) {
                switch (value) {
                  case 'select_new':
                    _selectNewSources();
                    break;
                  case 'select_update':
                    _selectUpdateSources();
                    break;
                  case 'custom_group':
                    _showCustomGroupDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'select_new',
                  child: Text('仅选择新书源'),
                ),
                const PopupMenuItem(
                  value: 'select_update',
                  child: Text('仅选择更新书源'),
                ),
                const PopupMenuItem(
                  value: 'custom_group',
                  child: Text('自定义分组'),
                ),
              ],
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _buildContent(theme),
      ),
      actions: [
        if (!_isLoading && _error == null) ...[
          TextButton(
            onPressed: () => _selectAll(!_isSelectAll),
            child: Text(
              _isSelectAll ? '全不选' : '全选',
              style: TextStyle(color: theme.primary),
            ),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '取消',
            style: TextStyle(color: theme.subText),
          ),
        ),
        if (!_isLoading && _error == null)
          TextButton(
            onPressed: _selectedCount > 0 ? _importSelected : null,
            child: Text(
              '导入($_selectedCount)',
              style: TextStyle(
                color: _selectedCount > 0 ? theme.primary : theme.subText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(AppThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary),
            const SizedBox(height: 16),
            Text(
              '正在解析书源...',
              style: TextStyle(color: theme.subText),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_allSources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.source, color: theme.subText, size: 48),
            const SizedBox(height: 16),
            Text(
              '未找到书源',
              style: TextStyle(color: theme.subText),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 导入选项
        ExpansionTile(
          title: Text(
            '导入选项',
            style: TextStyle(color: theme.onSurface, fontSize: 14),
          ),
          children: [
            CheckboxListTile(
              title: Text(
                '保留原有名称',
                style: TextStyle(color: theme.onSurface, fontSize: 13),
              ),
              value: _keepOriginalName,
              onChanged: (v) => setState(() => _keepOriginalName = v!),
              dense: true,
            ),
            CheckboxListTile(
              title: Text(
                '保留原有分组',
                style: TextStyle(color: theme.onSurface, fontSize: 13),
              ),
              value: _keepGroup,
              onChanged: (v) => setState(() => _keepGroup = v!),
              dense: true,
            ),
            CheckboxListTile(
              title: Text(
                '保留启用状态',
                style: TextStyle(color: theme.onSurface, fontSize: 13),
              ),
              value: _keepEnable,
              onChanged: (v) => setState(() => _keepEnable = v!),
              dense: true,
            ),
          ],
        ),
        const Divider(),
        // 书源列表
        Expanded(
          child: ListView.builder(
            itemCount: _allSources.length,
            itemBuilder: (context, index) {
              final source = _allSources[index];
              final isSelected = _selectStatus[index];
              final isNew = _isNewSource[index];
              final isUpdate = _isUpdateSource[index];

              String statusText;
              Color statusColor;
              if (isNew) {
                statusText = '新增';
                statusColor = Colors.green;
              } else if (isUpdate) {
                statusText = '更新';
                statusColor = Colors.orange;
              } else {
                statusText = '已有';
                statusColor = theme.subText;
              }

              return CheckboxListTile(
                title: Text(
                  source.bookSourceName,
                  style: TextStyle(
                    color: theme.onSurface,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  source.bookSourceUrl,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                    ),
                  ),
                ),
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    _selectStatus[index] = v!;
                  });
                },
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCustomGroupDialog() {
    final theme = ref.read(themeNotifierProvider);
    final controller = TextEditingController(text: _customGroup);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '自定义分组',
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
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text(
                '添加到现有分组',
                style: TextStyle(color: theme.onSurface, fontSize: 13),
              ),
              subtitle: Text(
                '不勾选则替换原有分组',
                style: TextStyle(color: theme.subText, fontSize: 11),
              ),
              value: _isAddGroup,
              onChanged: (v) => setState(() => _isAddGroup = v!),
              dense: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: theme.subText)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _customGroup = controller.text.isEmpty ? null : controller.text;
              });
              Navigator.pop(context);
            },
            child: Text('确定', style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }
}

/// 网络导入对话框
class ImportFromUrlDialog extends ConsumerStatefulWidget {
  const ImportFromUrlDialog({super.key});

  @override
  ConsumerState<ImportFromUrlDialog> createState() => _ImportFromUrlDialogState();
}

class _ImportFromUrlDialogState extends ConsumerState<ImportFromUrlDialog> {
  final TextEditingController _urlController = TextEditingController();
  List<String> _historyUrls = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // TODO: 从SharedPreferences加载历史记录
    setState(() {
      _historyUrls = [
        'https://cdn.jsdelivr.net/gh/yueduqi/shuyuan@main/shuyuan.json',
      ];
    });
  }

  Future<void> _saveHistory(String url) async {
    // TODO: 保存到SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return AlertDialog(
      backgroundColor: theme.surface,
      title: Text(
        '网络导入',
        style: TextStyle(color: theme.onSurface),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
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
            if (_historyUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '历史记录',
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _historyUrls.map((url) => ActionChip(
                  label: Text(
                    url.length > 30 ? '${url.substring(0, 30)}...' : url,
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    _urlController.text = url;
                  },
                )).toList(),
              ),
            ],
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
            final url = _urlController.text.trim();
            if (url.isNotEmpty) {
              await _saveHistory(url);
              if (mounted) {
                Navigator.pop(context, url);
              }
            }
          },
          child: Text(
            '确定',
            style: TextStyle(color: theme.primary),
          ),
        ),
      ],
    );
  }
}
