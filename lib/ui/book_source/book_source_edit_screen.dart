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

class BookSourceEditScreen extends ConsumerStatefulWidget {
  final String? sourceUrl;

  const BookSourceEditScreen({super.key, this.sourceUrl});

  @override
  ConsumerState<BookSourceEditScreen> createState() => _BookSourceEditScreenState();
}

class _BookSourceEditScreenState extends ConsumerState<BookSourceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _groupController = TextEditingController();
  final _commentController = TextEditingController();
  final _searchUrlController = TextEditingController();
  final _exploreUrlController = TextEditingController();

  int _currentTab = 0;
  bool _isLoading = true;
  BookSource? _source;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  Future<void> _loadSource() async {
    if (widget.sourceUrl != null) {
      final repository = ref.read(bookSourceRepositoryProvider);
      _source = await repository.getSource(widget.sourceUrl!);
      if (_source != null) {
        _nameController.text = _source!.bookSourceName;
        _urlController.text = _source!.bookSourceUrl;
        _groupController.text = _source!.bookSourceGroup ?? '';
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _groupController.dispose();
    _commentController.dispose();
    _searchUrlController.dispose();
    _exploreUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSource() async {
    if (_formKey.currentState!.validate()) {
      // TODO: 保存书源到数据库
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: widget.sourceUrl == null ? '添加书源' : '编辑书源',
        actions: [
          TextButton(
            onPressed: _saveSource,
            child: Text(
              '保存',
              style: TextStyle(color: theme.primary),
            ),
          ),
        ],
      ),
      body: Container(
        color: theme.background,
        child: Column(
          children: [
            Container(
              height: 48,
              color: theme.surface,
              child: Row(
                children: [
                  _buildTab(0, '基本信息', theme),
                  _buildTab(1, '搜索规则', theme),
                  _buildTab(2, '发现规则', theme),
                  _buildTab(3, '调试', theme),
                ],
              ),
            ),
            const GoldDivider(),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildBasicInfoTab(theme),
                  _buildSearchRuleTab(theme),
                  _buildExploreRuleTab(theme),
                  _buildDebugTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String title, AppThemeData theme) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTab = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? theme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? theme.primary : theme.subText,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(AppThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTextField(
            controller: _nameController,
            label: '书源名称',
            hint: '请输入书源名称',
            theme: theme,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入书源名称';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _urlController,
            label: '书源地址',
            hint: '请输入书源地址',
            theme: theme,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入书源地址';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _groupController,
            label: '书源分组',
            hint: '请输入书源分组',
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _commentController,
            label: '书源备注',
            hint: '请输入书源备注',
            theme: theme,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: true,
                onChanged: (value) {},
                activeColor: theme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '启用书源',
                style: TextStyle(color: theme.onBackground),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: true,
                onChanged: (value) {},
                activeColor: theme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '启用发现',
                style: TextStyle(color: theme.onBackground),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRuleTab(AppThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTextField(
          controller: _searchUrlController,
          label: '搜索地址',
          hint: '请输入搜索地址',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '搜索列表规则',
          hint: '请输入搜索列表规则',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '书名规则',
          hint: '请输入书名规则',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '作者规则',
          hint: '请输入作者规则',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '封面规则',
          hint: '请输入封面规则',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '简介规则',
          hint: '请输入简介规则',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '详情页规则',
          hint: '请输入详情页规则',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildExploreRuleTab(AppThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTextField(
          controller: _exploreUrlController,
          label: '发现地址',
          hint: '请输入发现地址',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '发现规则',
          hint: '请输入发现规则',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '目录规则',
          hint: '请输入目录规则',
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildRuleEditor(
          label: '正文规则',
          hint: '请输入正文规则',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildDebugTab(AppThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '书源调试',
          style: TextStyle(
            color: theme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: '测试关键词',
          hint: '请输入测试关键词',
          theme: theme,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: 执行搜索测试
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('测试搜索'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '调试结果',
          style: TextStyle(
            color: theme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.divider),
          ),
          child: Text(
            '点击"测试搜索"按钮查看结果',
            style: TextStyle(color: theme.subText),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required AppThemeData theme,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: theme.onBackground),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.subText),
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
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRuleEditor({
    required String label,
    required String hint,
    required AppThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: theme.onBackground),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: theme.subText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: theme.primary),
                onPressed: () {
                  // TODO: 打开规则编辑器
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
