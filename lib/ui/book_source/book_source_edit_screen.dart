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
import 'book_source_debug_screen.dart';

class BookSourceEditScreen extends ConsumerStatefulWidget {
  final String? sourceUrl;

  const BookSourceEditScreen({super.key, this.sourceUrl});

  @override
  ConsumerState<BookSourceEditScreen> createState() => _BookSourceEditScreenState();
}

class _BookSourceEditScreenState extends ConsumerState<BookSourceEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  BookSource? _source;

  // 基本信息
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _groupController = TextEditingController();
  final _commentController = TextEditingController();
  final _loginUrlController = TextEditingController();
  final _loginUiController = TextEditingController();
  final _loginCheckJsController = TextEditingController();
  final _concurrentRateController = TextEditingController();
  final _jsLibController = TextEditingController();

  // 请求头 - 使用Map存储键值对
  Map<String, String> _headers = {};

  // 搜索规则
  final _searchUrlController = TextEditingController();
  final _checkKeyWordController = TextEditingController();
  final _searchBookListController = TextEditingController();
  final _searchNameController = TextEditingController();
  final _searchAuthorController = TextEditingController();
  final _searchKindController = TextEditingController();
  final _searchWordCountController = TextEditingController();
  final _searchLastChapterController = TextEditingController();
  final _searchIntroController = TextEditingController();
  final _searchCoverUrlController = TextEditingController();
  final _searchBookUrlController = TextEditingController();

  // 发现规则
  final _exploreUrlController = TextEditingController();
  final _exploreBookListController = TextEditingController();
  final _exploreNameController = TextEditingController();
  final _exploreAuthorController = TextEditingController();
  final _exploreKindController = TextEditingController();
  final _exploreWordCountController = TextEditingController();
  final _exploreLastChapterController = TextEditingController();
  final _exploreIntroController = TextEditingController();
  final _exploreCoverUrlController = TextEditingController();
  final _exploreBookUrlController = TextEditingController();

  // 书籍信息规则
  final _infoInitController = TextEditingController();
  final _infoNameController = TextEditingController();
  final _infoAuthorController = TextEditingController();
  final _infoKindController = TextEditingController();
  final _infoWordCountController = TextEditingController();
  final _infoLastChapterController = TextEditingController();
  final _infoIntroController = TextEditingController();
  final _infoCoverUrlController = TextEditingController();
  final _infoTocUrlController = TextEditingController();

  // 目录规则
  final _tocChapterListController = TextEditingController();
  final _tocChapterNameController = TextEditingController();
  final _tocChapterUrlController = TextEditingController();
  final _tocNextTocUrlController = TextEditingController();

  // 正文规则
  final _contentController = TextEditingController();
  final _contentTitleController = TextEditingController();
  final _contentNextUrlController = TextEditingController();
  final _contentReplaceRegexController = TextEditingController();

  bool _enabled = true;
  bool _enabledExplore = true;
  int _sourceType = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadSource();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _urlController.dispose();
    _nameController.dispose();
    _groupController.dispose();
    _commentController.dispose();
    _loginUrlController.dispose();
    _loginUiController.dispose();
    _loginCheckJsController.dispose();
    _concurrentRateController.dispose();
    _jsLibController.dispose();
    _searchUrlController.dispose();
    _checkKeyWordController.dispose();
    _searchBookListController.dispose();
    _searchNameController.dispose();
    _searchAuthorController.dispose();
    _searchKindController.dispose();
    _searchWordCountController.dispose();
    _searchLastChapterController.dispose();
    _searchIntroController.dispose();
    _searchCoverUrlController.dispose();
    _searchBookUrlController.dispose();
    _exploreUrlController.dispose();
    _exploreBookListController.dispose();
    _exploreNameController.dispose();
    _exploreAuthorController.dispose();
    _exploreKindController.dispose();
    _exploreWordCountController.dispose();
    _exploreLastChapterController.dispose();
    _exploreIntroController.dispose();
    _exploreCoverUrlController.dispose();
    _exploreBookUrlController.dispose();
    _infoInitController.dispose();
    _infoNameController.dispose();
    _infoAuthorController.dispose();
    _infoKindController.dispose();
    _infoWordCountController.dispose();
    _infoLastChapterController.dispose();
    _infoIntroController.dispose();
    _infoCoverUrlController.dispose();
    _infoTocUrlController.dispose();
    _tocChapterListController.dispose();
    _tocChapterNameController.dispose();
    _tocChapterUrlController.dispose();
    _tocNextTocUrlController.dispose();
    _contentController.dispose();
    _contentTitleController.dispose();
    _contentNextUrlController.dispose();
    _contentReplaceRegexController.dispose();
  }

  Future<void> _loadSource() async {
    if (widget.sourceUrl != null) {
      final repository = ref.read(bookSourceRepositoryProvider);
      _source = await repository.getSource(widget.sourceUrl!);
      if (_source != null) {
        _fillControllers(_source!);
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fillControllers(BookSource source) {
    // 基本信息
    _urlController.text = source.bookSourceUrl;
    _nameController.text = source.bookSourceName;
    _groupController.text = source.bookSourceGroup ?? '';
    _commentController.text = source.bookSourceComment ?? '';
    _loginUrlController.text = source.loginUrl ?? '';
    _loginUiController.text = source.loginUi ?? '';
    _loginCheckJsController.text = source.loginCheckJs ?? '';
    _concurrentRateController.text = source.concurrentRate ?? '';
    _jsLibController.text = source.jsLib ?? '';
    _enabled = source.enabled;
    _enabledExplore = source.enabledExplore;
    _sourceType = source.bookSourceType;

    // 解析请求头
    _headers = _parseHeaders(source.header);

    // 搜索规则
    _searchUrlController.text = source.searchUrl ?? '';

    // 发现规则
    _exploreUrlController.text = source.exploreUrl ?? '';

    // 目录规则
    _tocChapterListController.text = source.ruleToc ?? '';

    // 正文规则
    _contentController.text = source.ruleContent ?? '';
  }

  BookSource _buildSource() {
    return BookSource(
      bookSourceUrl: _urlController.text,
      bookSourceName: _nameController.text,
      bookSourceGroup: _groupController.text.isEmpty ? null : _groupController.text,
      bookSourceComment: _commentController.text.isEmpty ? null : _commentController.text,
      loginUrl: _loginUrlController.text.isEmpty ? null : _loginUrlController.text,
      loginUi: _loginUiController.text.isEmpty ? null : _loginUiController.text,
      loginCheckJs: _loginCheckJsController.text.isEmpty ? null : _loginCheckJsController.text,
      header: _headers.isEmpty ? null : _formatHeaders(_headers),
      concurrentRate: _concurrentRateController.text.isEmpty ? null : _concurrentRateController.text,
      jsLib: _jsLibController.text.isEmpty ? null : _jsLibController.text,
      enabled: _enabled,
      enabledExplore: _enabledExplore,
      bookSourceType: _sourceType,
      searchUrl: _searchUrlController.text.isEmpty ? null : _searchUrlController.text,
      exploreUrl: _exploreUrlController.text.isEmpty ? null : _exploreUrlController.text,
      ruleSearch: _searchBookListController.text.isEmpty ? null : _searchBookListController.text,
      ruleExplore: _exploreBookListController.text.isEmpty ? null : _exploreBookListController.text,
      ruleBookInfo: _infoInitController.text.isEmpty ? null : _infoInitController.text,
      ruleToc: _tocChapterListController.text.isEmpty ? null : _tocChapterListController.text,
      ruleContent: _contentController.text.isEmpty ? null : _contentController.text,
      respondTime: _source?.respondTime ?? 100,
      lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _saveSource() async {
    final source = _buildSource();
    if (source.bookSourceUrl.isEmpty || source.bookSourceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书源名称和URL不能为空')),
      );
      return;
    }

    final repository = ref.read(bookSourceRepositoryProvider);
    await repository.saveSource(source);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书源已保存')),
      );
      Navigator.pop(context);
    }
  }

  void _debugSource() {
    final source = _buildSource();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookSourceDebugScreen(
          sourceUrl: source.bookSourceUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: widget.sourceUrl == null ? '添加书源' : '编辑书源',
        actions: [
          TextButton(
            onPressed: _debugSource,
            child: Text(
              '调试',
              style: TextStyle(color: theme.background),
            ),
          ),
          TextButton(
            onPressed: _saveSource,
            child: Text(
              '保存',
              style: TextStyle(color: theme.background),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.background,
          unselectedLabelColor: theme.background.withOpacity(0.7),
          indicatorColor: theme.background,
          tabs: const [
            Tab(text: '基本信息'),
            Tab(text: '搜索规则'),
            Tab(text: '发现规则'),
            Tab(text: '书籍信息'),
            Tab(text: '目录规则'),
            Tab(text: '正文规则'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBaseTab(theme),
                _buildSearchTab(theme),
                _buildExploreTab(theme),
                _buildBookInfoTab(theme),
                _buildTocTab(theme),
                _buildContentTab(theme),
              ],
            ),
    );
  }

  Widget _buildBaseTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitchRow(
            '启用书源',
            _enabled,
            (value) => setState(() => _enabled = value),
            theme,
          ),
          _buildSwitchRow(
            '启用发现',
            _enabledExplore,
            (value) => setState(() => _enabledExplore = value),
            theme,
          ),
          const SizedBox(height: 16),
          _buildTextField('书源名称', _nameController, theme, required: true),
          _buildTextField('书源URL', _urlController, theme, required: true),
          _buildTextField('书源分组', _groupController, theme),
          _buildTextField('注释', _commentController, theme, maxLines: 3),
          _buildTextField('登录URL', _loginUrlController, theme),
          _buildTextField('登录UI', _loginUiController, theme),
          _buildTextField('登录检测JS', _loginCheckJsController, theme, maxLines: 3),
          _buildHeaderEditor(theme),
          const SizedBox(height: 16),
          _buildTextField('并发率', _concurrentRateController, theme),
          _buildTextField('JS库', _jsLibController, theme, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildSearchTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('搜索地址', _searchUrlController, theme),
          _buildTextField('校验关键字', _checkKeyWordController, theme),
          _buildTextField('书籍列表', _searchBookListController, theme),
          _buildTextField('书名', _searchNameController, theme),
          _buildTextField('作者', _searchAuthorController, theme),
          _buildTextField('分类', _searchKindController, theme),
          _buildTextField('字数', _searchWordCountController, theme),
          _buildTextField('最新章节', _searchLastChapterController, theme),
          _buildTextField('简介', _searchIntroController, theme),
          _buildTextField('封面', _searchCoverUrlController, theme),
          _buildTextField('书籍链接', _searchBookUrlController, theme),
        ],
      ),
    );
  }

  Widget _buildExploreTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('发现地址', _exploreUrlController, theme),
          _buildTextField('书籍列表', _exploreBookListController, theme),
          _buildTextField('书名', _exploreNameController, theme),
          _buildTextField('作者', _exploreAuthorController, theme),
          _buildTextField('分类', _exploreKindController, theme),
          _buildTextField('字数', _exploreWordCountController, theme),
          _buildTextField('最新章节', _exploreLastChapterController, theme),
          _buildTextField('简介', _exploreIntroController, theme),
          _buildTextField('封面', _exploreCoverUrlController, theme),
          _buildTextField('书籍链接', _exploreBookUrlController, theme),
        ],
      ),
    );
  }

  Widget _buildBookInfoTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('预处理', _infoInitController, theme),
          _buildTextField('书名', _infoNameController, theme),
          _buildTextField('作者', _infoAuthorController, theme),
          _buildTextField('分类', _infoKindController, theme),
          _buildTextField('字数', _infoWordCountController, theme),
          _buildTextField('最新章节', _infoLastChapterController, theme),
          _buildTextField('简介', _infoIntroController, theme),
          _buildTextField('封面', _infoCoverUrlController, theme),
          _buildTextField('目录URL', _infoTocUrlController, theme),
        ],
      ),
    );
  }

  Widget _buildTocTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('章节列表', _tocChapterListController, theme),
          _buildTextField('章节名称', _tocChapterNameController, theme),
          _buildTextField('章节链接', _tocChapterUrlController, theme),
          _buildTextField('下一页目录', _tocNextTocUrlController, theme),
        ],
      ),
    );
  }

  Widget _buildContentTab(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('正文内容', _contentController, theme, maxLines: 5),
          _buildTextField('章节标题', _contentTitleController, theme),
          _buildTextField('下一页正文', _contentNextUrlController, theme),
          _buildTextField('替换规则', _contentReplaceRegexController, theme, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    AppThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    AppThemeData theme, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.onSurface),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: TextStyle(color: theme.subText),
          filled: true,
          fillColor: theme.surface,
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
    );
  }

  // ========== 请求头管理 ==========

  /// 解析请求头字符串为Map
  Map<String, String> _parseHeaders(String? headerStr) {
    if (headerStr == null || headerStr.isEmpty) return {};
    
    final headers = <String, String>{};
    try {
      // 尝试解析为JSON
      final decoded = jsonDecode(headerStr);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          headers[key.toString()] = value.toString();
        });
        return headers;
      }
    } catch (e) {
      // 不是JSON，按行解析
      final lines = headerStr.split('\n');
      for (final line in lines) {
        final index = line.indexOf(':');
        if (index > 0) {
          final key = line.substring(0, index).trim();
          final value = line.substring(index + 1).trim();
          if (key.isNotEmpty) {
            headers[key] = value;
          }
        }
      }
    }
    return headers;
  }

  /// 将Map格式化为请求头字符串
  String _formatHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return '';
    return jsonEncode(headers);
  }

  /// 构建请求头编辑器
  Widget _buildHeaderEditor(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '请求头',
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddHeaderDialog(theme),
              icon: Icon(Icons.add, color: theme.primary, size: 18),
              label: Text(
                '添加',
                style: TextStyle(color: theme.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_headers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.divider),
            ),
            child: Center(
              child: Text(
                '暂无请求头',
                style: TextStyle(color: theme.subText),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.divider),
            ),
            child: Column(
              children: _headers.entries.map((entry) {
                return ListTile(
                  dense: true,
                  title: Text(
                    entry.key,
                    style: TextStyle(
                      color: theme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    entry.value,
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: theme.error, size: 20),
                    onPressed: () {
                      setState(() {
                        _headers.remove(entry.key);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showAddHeaderDialog(AppThemeData theme) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '添加请求头',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: 'Header名称',
                labelStyle: TextStyle(color: theme.subText),
                hintText: '如: User-Agent',
                hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                filled: true,
                fillColor: theme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: 'Header值',
                labelStyle: TextStyle(color: theme.subText),
                hintText: '如: Mozilla/5.0...',
                hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                filled: true,
                fillColor: theme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
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
              final key = keyController.text.trim();
              final value = valueController.text.trim();
              if (key.isNotEmpty && value.isNotEmpty) {
                setState(() {
                  _headers[key] = value;
                });
                Navigator.pop(context);
              }
            },
            child: Text('确定', style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }
}
