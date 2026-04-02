import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../data/database/daos/replace_rule_dao.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';

class ReplaceRuleScreen extends ConsumerStatefulWidget {
  const ReplaceRuleScreen({super.key});

  @override
  ConsumerState<ReplaceRuleScreen> createState() => _ReplaceRuleScreenState();
}

class _ReplaceRuleScreenState extends ConsumerState<ReplaceRuleScreen> {
  final ReplaceRuleDao _dao = ReplaceRuleDao();
  List<ReplaceRule> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
    });
    final rules = await _dao.getAllRules();
    setState(() {
      _rules = rules;
      _isLoading = false;
    });
  }

  Future<void> _deleteRule(int id) async {
    await _dao.deleteRule(id);
    await _loadRules();
  }

  Future<void> _toggleEnabled(int id, bool enabled) async {
    await _dao.toggleEnabled(id, enabled);
    await _loadRules();
  }

  void _showAddEditDialog({ReplaceRule? rule}) {
    final nameController = TextEditingController(text: rule?.name ?? '');
    final patternController = TextEditingController(text: rule?.pattern ?? '');
    final replacementController = TextEditingController(text: rule?.replacement ?? '');
    final scopeController = TextEditingController(text: rule?.scope ?? '');
    bool isRegex = rule?.isRegex ?? true;

    showDialog(
      context: context,
      builder: (context) {
        final theme = ref.read(themeNotifierProvider);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surface,
              title: Text(
                rule == null ? '添加替换规则' : '编辑替换规则',
                style: TextStyle(color: theme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: theme.onSurface),
                      decoration: InputDecoration(
                        labelText: '规则名称',
                        labelStyle: TextStyle(color: theme.subText),
                        filled: true,
                        fillColor: theme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: patternController,
                      style: TextStyle(color: theme.onSurface),
                      decoration: InputDecoration(
                        labelText: '匹配规则',
                        labelStyle: TextStyle(color: theme.subText),
                        hintText: '正则表达式或普通文本',
                        hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                        filled: true,
                        fillColor: theme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: replacementController,
                      style: TextStyle(color: theme.onSurface),
                      decoration: InputDecoration(
                        labelText: '替换为',
                        labelStyle: TextStyle(color: theme.subText),
                        hintText: '留空表示删除匹配内容',
                        hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                        filled: true,
                        fillColor: theme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scopeController,
                      style: TextStyle(color: theme.onSurface),
                      decoration: InputDecoration(
                        labelText: '作用范围（可选）',
                        labelStyle: TextStyle(color: theme.subText),
                        hintText: '书籍名称，留空表示全局',
                        hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                        filled: true,
                        fillColor: theme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(
                        '使用正则表达式',
                        style: TextStyle(color: theme.onSurface),
                      ),
                      value: isRegex,
                      onChanged: (value) {
                        setDialogState(() {
                          isRegex = value;
                        });
                      },
                      activeColor: theme.primary,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消', style: TextStyle(color: theme.subText)),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        patternController.text.trim().isEmpty) {
                      return;
                    }

                    final newRule = ReplaceRule(
                      id: rule?.id ?? 0,
                      name: nameController.text.trim(),
                      pattern: patternController.text.trim(),
                      replacement: replacementController.text.trim(),
                      scope: scopeController.text.isEmpty ? null : scopeController.text.trim(),
                      isRegex: isRegex,
                      enabled: rule?.enabled ?? true,
                      order: rule?.order ?? _rules.length,
                    );

                    await _dao.insertOrUpdateRule(newRule);
                    await _loadRules();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text('保存', style: TextStyle(color: theme.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTestDialog() {
    final textController = TextEditingController();
    final resultController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final theme = ref.read(themeNotifierProvider);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surface,
              title: Text(
                '测试替换规则',
                style: TextStyle(color: theme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      style: TextStyle(color: theme.onSurface),
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: '输入测试文本',
                        labelStyle: TextStyle(color: theme.subText),
                        filled: true,
                        fillColor: theme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await _dao.applyRules(textController.text);
                          setDialogState(() {
                            resultController.text = result;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: theme.background,
                        ),
                        child: const Text('应用替换规则'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: resultController,
                      style: TextStyle(color: theme.onSurface),
                      maxLines: 5,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: '替换结果',
                        labelStyle: TextStyle(color: theme.subText),
                        filled: true,
                        fillColor: theme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('关闭', style: TextStyle(color: theme.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '替换规则',
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _showTestDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : _rules.isEmpty
              ? _buildEmptyView(theme)
              : _buildRuleList(theme),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.find_replace, size: 64, color: theme.subText),
          const SizedBox(height: 16),
          Text(
            '暂无替换规则',
            style: TextStyle(color: theme.subText, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角添加规则',
            style: TextStyle(color: theme.subText.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleList(AppThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return Card(
          color: theme.surface,
          child: ListTile(
            title: Text(
              rule.name,
              style: TextStyle(
                color: theme.onSurface,
                fontWeight: FontWeight.w500,
                decoration: rule.enabled ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '匹配: ${rule.pattern}',
                  style: TextStyle(color: theme.subText, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '替换: ${rule.replacement.isEmpty ? "(删除)" : rule.replacement}',
                  style: TextStyle(color: theme.subText, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rule.scope != null)
                  Text(
                    '范围: ${rule.scope}',
                    style: TextStyle(color: theme.primary, fontSize: 11),
                  ),
                Row(
                  children: [
                    Icon(
                      rule.isRegex ? Icons.code : Icons.text_fields,
                      size: 14,
                      color: theme.subText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rule.isRegex ? '正则' : '普通文本',
                      style: TextStyle(color: theme.subText, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: rule.enabled,
                  onChanged: (value) => _toggleEnabled(rule.id, value),
                  activeColor: theme.primary,
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.subText),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEditDialog(rule: rule);
                    } else if (value == 'delete') {
                      _deleteRule(rule.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: theme.error),
                          const SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: theme.error)),
                        ],
                      ),
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
}
