import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import 'book_source_list_screen.dart';

enum DebugStep {
  search,
  bookInfo,
  toc,
  content,
}

class BookSourceDebugScreen extends ConsumerStatefulWidget {
  final BookSourceItem? source;

  const BookSourceDebugScreen({super.key, this.source});

  @override
  ConsumerState<BookSourceDebugScreen> createState() => _BookSourceDebugScreenState();
}

class _BookSourceDebugScreenState extends ConsumerState<BookSourceDebugScreen> {
  final TextEditingController _searchKeywordController = TextEditingController();
  DebugStep _currentStep = DebugStep.search;
  bool _isLoading = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _searchKeywordController.dispose();
    super.dispose();
  }

  Future<void> _executeDebug() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _result = '''调试结果示例：
================

步骤: ${_getStepName(_currentStep)}
书源: ${widget.source?.name ?? '未选择'}
关键词: ${_searchKeywordController.text}

解析规则执行成功！
返回结果数量: 5
耗时: 123ms

{
  "success": true,
  "data": [
    {
      "name": "示例书籍1",
      "author": "作者1",
      "coverUrl": "https://example.com/cover1.jpg"
    },
    {
      "name": "示例书籍2",
      "author": "作者2",
      "coverUrl": "https://example.com/cover2.jpg"
    }
  ]
}
''';
      });
    }
  }

  String _getStepName(DebugStep step) {
    switch (step) {
      case DebugStep.search:
        return '搜索规则';
      case DebugStep.bookInfo:
        return '书籍详情';
      case DebugStep.toc:
        return '目录规则';
      case DebugStep.content:
        return '正文规则';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '书源调试',
      ),
      body: Container(
        color: theme.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '书源: ${widget.source?.name ?? '未选择书源'}',
                    style: TextStyle(
                      color: theme.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStepSelector(theme),
                  const SizedBox(height: 16),
                  if (_currentStep == DebugStep.search) ...[
                    TextField(
                      controller: _searchKeywordController,
                      style: TextStyle(color: theme.onBackground),
                      decoration: InputDecoration(
                        hintText: '输入搜索关键词...',
                        hintStyle: TextStyle(color: theme.subText),
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
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _executeDebug,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.background,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('执行中...'),
                              ],
                            )
                          : const Text('执行调试'),
                    ),
                  ),
                ],
              ),
            ),
            const GoldDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.error),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, color: theme.error),
                                const SizedBox(width: 8),
                                Text(
                                  '错误',
                                  style: TextStyle(
                                    color: theme.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(color: theme.error),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_result != null) ...[
                      Text(
                        '调试结果',
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.divider),
                        ),
                        child: SelectableText(
                          _result!,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                    if (_result == null && _error == null)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.terminal,
                              size: 64,
                              color: theme.primary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '点击上方按钮开始调试',
                              style: TextStyle(
                                color: theme.subText,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSelector(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: DebugStep.values.map((step) {
          final isSelected = _currentStep == step;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = step;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStepName(step),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? theme.background : theme.onSurface,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
