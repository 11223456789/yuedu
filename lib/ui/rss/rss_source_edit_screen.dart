import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../data/database/daos/rss_source_dao.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';

class RssSourceEditScreen extends ConsumerStatefulWidget {
  final RssSource? source;

  const RssSourceEditScreen({super.key, this.source});

  @override
  ConsumerState<RssSourceEditScreen> createState() => _RssSourceEditScreenState();
}

class _RssSourceEditScreenState extends ConsumerState<RssSourceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _groupController = TextEditingController();
  final _commentController = TextEditingController();
  final _headerController = TextEditingController();
  
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.source != null) {
      _nameController.text = widget.source!.sourceName;
      _urlController.text = widget.source!.sourceUrl;
      _groupController.text = widget.source!.sourceGroup ?? '';
      _commentController.text = widget.source!.sourceComment ?? '';
      _headerController.text = widget.source!.header ?? '';
      _enabled = widget.source!.enabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _groupController.dispose();
    _commentController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _saveSource() async {
    if (!_formKey.currentState!.validate()) return;

    final source = RssSource(
      sourceUrl: _urlController.text.trim(),
      sourceName: _nameController.text.trim(),
      sourceGroup: _groupController.text.isEmpty ? null : _groupController.text.trim(),
      sourceComment: _commentController.text.isEmpty ? null : _commentController.text.trim(),
      enabled: _enabled,
      header: _headerController.text.isEmpty ? null : _headerController.text.trim(),
      lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
    );

    final dao = RssSourceDao();
    await dao.insertOrUpdateSource(source);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: widget.source == null ? '添加RSS源' : '编辑RSS源',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: 'RSS源名称 *',
                labelStyle: TextStyle(color: theme.subText),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入RSS源名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: 'RSS源地址 *',
                labelStyle: TextStyle(color: theme.subText),
                hintText: 'https://example.com/feed.xml',
                hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入RSS源地址';
                }
                if (!value.startsWith('http')) {
                  return '地址必须以http或https开头';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _groupController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: '分组',
                labelStyle: TextStyle(color: theme.subText),
                hintText: '可选，用于分类管理',
                hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              style: TextStyle(color: theme.onSurface),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '备注',
                labelStyle: TextStyle(color: theme.subText),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _headerController,
              style: TextStyle(color: theme.onSurface),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '请求头',
                labelStyle: TextStyle(color: theme.subText),
                hintText: '{"User-Agent": "Mozilla/5.0"}',
                hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                '启用',
                style: TextStyle(color: theme.onSurface),
              ),
              value: _enabled,
              onChanged: (value) {
                setState(() {
                  _enabled = value;
                });
              },
              activeColor: theme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
