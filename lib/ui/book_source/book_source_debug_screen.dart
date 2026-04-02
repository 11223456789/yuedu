import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../data/repositories/book_source_repository.dart';
import '../../data/database/daos/book_source_dao.dart';
import '../../model/analyze_rule/analyze_rule.dart';
import '../../model/analyze_rule/analyze_url.dart';
import '../../model/web_book/web_book.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';

enum DebugStep {
  search,
  bookInfo,
  toc,
  content,
}

class BookSourceDebugScreen extends ConsumerStatefulWidget {
  final String? sourceUrl;

  const BookSourceDebugScreen({super.key, this.sourceUrl});

  @override
  ConsumerState<BookSourceDebugScreen> createState() => _BookSourceDebugScreenState();
}

class _BookSourceDebugScreenState extends ConsumerState<BookSourceDebugScreen> {
  final TextEditingController _searchKeywordController = TextEditingController(text: '斗破苍穹');
  final TextEditingController _bookUrlController = TextEditingController();
  final TextEditingController _chapterUrlController = TextEditingController();
  DebugStep _currentStep = DebugStep.search;
  bool _isLoading = false;
  String? _result;
  String? _error;
  BookSource? _source;
  List<SearchBook> _searchResults = [];
  Book? _currentBook;
  List<BookChapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  Future<void> _loadSource() async {
    if (widget.sourceUrl != null) {
      final repository = ref.read(bookSourceRepositoryProvider);
      _source = await repository.getSource(widget.sourceUrl!);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _searchKeywordController.dispose();
    _bookUrlController.dispose();
    _chapterUrlController.dispose();
    super.dispose();
  }

  Future<void> _executeDebug() async {
    if (_source == null) {
      setState(() {
        _error = '请先选择书源';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      switch (_currentStep) {
        case DebugStep.search:
          await _debugSearch();
          break;
        case DebugStep.bookInfo:
          await _debugBookInfo();
          break;
        case DebugStep.toc:
          await _debugToc();
          break;
        case DebugStep.content:
          await _debugContent();
          break;
      }
    } catch (e, stackTrace) {
      setState(() {
        _error = '调试失败: $e\n\n$stackTrace';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugSearch() async {
    final keyword = _searchKeywordController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _error = '请输入搜索关键词';
      });
      return;
    }

    final results = await WebBook.search(_source!, keyword);
    _searchResults = results;

    if (results.isEmpty) {
      setState(() {
        _result = '搜索完成，但未找到任何结果\n\n请检查：\n1. 搜索规则是否正确\n2. 书源是否可用\n3. 网络连接是否正常';
      });
    } else {
      setState(() {
        _result = '''搜索成功！
================

找到 ${results.length} 本书籍：

${results.asMap().entries.map((e) => '''
[${e.key + 1}] ${e.value.name}
    作者: ${e.value.author}
    链接: ${e.value.bookUrl}
    ${e.value.coverUrl != null ? '封面: ${e.value.coverUrl}' : ''}
''').join('\n')}

点击任意书籍可继续调试书籍详情''';
        _currentBook = Book(bookUrl: results.first.bookUrl, name: results.first.name, author: results.first.author);
        _bookUrlController.text = results.first.bookUrl;
      });
    }
  }

  Future<void> _debugBookInfo() async {
    final bookUrl = _bookUrlController.text.trim();
    if (bookUrl.isEmpty) {
      setState(() {
        _error = '请输入书籍链接';
      });
      return;
    }

    final book = Book(bookUrl: bookUrl, name: '未知', author: '未知');
    final updatedBook = await WebBook.getBookInfo(_source!, book);

    setState(() {
      _currentBook = updatedBook;
      _result = '''书籍详情获取成功！
================

书名: ${updatedBook.name}
作者: ${updatedBook.author}
${updatedBook.coverUrl != null ? '封面: ${updatedBook.coverUrl}' : ''}
${updatedBook.intro != null ? '简介: ${updatedBook.intro}' : ''}
${updatedBook.kind != null ? '分类: ${updatedBook.kind}' : ''}
${updatedBook.latestChapterTitle != null ? '最新章节: ${updatedBook.latestChapterTitle}' : ''}
目录链接: ${updatedBook.tocUrl.isNotEmpty ? updatedBook.tocUrl : bookUrl}

可以继续调试目录解析''';
    });
  }

  Future<void> _debugToc() async {
    final bookUrl = _bookUrlController.text.trim();
    if (bookUrl.isEmpty) {
      setState(() {
        _error = '请输入书籍链接';
      });
      return;
    }

    final book = _currentBook ?? Book(bookUrl: bookUrl, name: '未知', author: '未知');
    final chapters = await WebBook.getChapterList(_source!, book);
    _chapters = chapters;

    if (chapters.isEmpty) {
      setState(() {
        _result = '目录获取完成，但未找到任何章节\n\n请检查：\n1. 目录规则是否正确\n2. 书籍链接是否有效';
      });
    } else {
      setState(() {
        _result = '''目录获取成功！
================

共 ${chapters.length} 个章节：

${chapters.take(10).map((c) => '[${c.index + 1}] ${c.title}\n    ${c.url}').join('\n\n')}
${chapters.length > 10 ? '\n... 还有 ${chapters.length - 10} 个章节' : ''}

点击任意章节可继续调试正文解析''';
        if (chapters.isNotEmpty) {
          _chapterUrlController.text = chapters.first.url;
        }
      });
    }
  }

  Future<void> _debugContent() async {
    final chapterUrl = _chapterUrlController.text.trim();
    if (chapterUrl.isEmpty) {
      setState(() {
        _error = '请输入章节链接';
      });
      return;
    }

    final bookUrl = _bookUrlController.text.trim();
    final book = _currentBook ?? Book(bookUrl: bookUrl.isNotEmpty ? bookUrl : chapterUrl, name: '未知', author: '未知');
    final chapter = BookChapter(
      url: chapterUrl,
      bookUrl: book.bookUrl,
      title: '调试章节',
      index: 0,
    );

    final content = await WebBook.getContent(_source!, book, chapter);

    setState(() {
      _result = '''正文获取成功！
================

章节链接: $chapterUrl
内容长度: ${content.length} 字符

内容预览（前500字符）：
----------------
${content.substring(0, content.length > 500 ? 500 : content.length)}
${content.length > 500 ? '\n... 还有 ${content.length - 500} 字符' : ''}

调试完成！''';
    });
  }

  String _getStepName(DebugStep step) {
    switch (step) {
      case DebugStep.search:
        return '搜索';
      case DebugStep.bookInfo:
        return '书籍详情';
      case DebugStep.toc:
        return '目录';
      case DebugStep.content:
        return '正文';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '书源调试',
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _isLoading ? null : _executeDebug,
          ),
        ],
      ),
      body: _source == null
          ? Center(
              child: Text(
                '请先选择书源',
                style: TextStyle(color: theme.subText),
              ),
            )
          : _buildContent(theme),
    );
  }

  Widget _buildContent(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 书源信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.source, color: theme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _source!.bookSourceName,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _source!.bookSourceUrl,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 调试步骤选择
          Text(
            '调试步骤',
            style: TextStyle(
              color: theme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: DebugStep.values.map((step) {
              final isSelected = _currentStep == step;
              return ChoiceChip(
                label: Text(_getStepName(step)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentStep = step;
                      _result = null;
                      _error = null;
                    });
                  }
                },
                selectedColor: theme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? theme.background : theme.onSurface,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // 输入参数
          if (_currentStep == DebugStep.search) ...[
            TextField(
              controller: _searchKeywordController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: '搜索关键词',
                labelStyle: TextStyle(color: theme.subText),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
            ),
          ],
          if (_currentStep == DebugStep.bookInfo || _currentStep == DebugStep.toc) ...[
            TextField(
              controller: _bookUrlController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: '书籍链接',
                labelStyle: TextStyle(color: theme.subText),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
            ),
          ],
          if (_currentStep == DebugStep.content) ...[
            TextField(
              controller: _chapterUrlController,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                labelText: '章节链接',
                labelStyle: TextStyle(color: theme.subText),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.divider),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 执行按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _executeDebug,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(theme.background),
                      ),
                    )
                  : const Text('开始调试'),
            ),
          ),
          const SizedBox(height: 16),
          const GoldDivider(),
          const SizedBox(height: 16),
          // 结果展示
          if (_isLoading)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: theme.primary),
                  const SizedBox(height: 16),
                  Text(
                    '正在调试...',
                    style: TextStyle(color: theme.subText),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
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
                      Icon(Icons.error, color: theme.error),
                      const SizedBox(width: 8),
                      Text(
                        '错误',
                        style: TextStyle(
                          color: theme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _error!,
                    style: TextStyle(color: theme.error),
                  ),
                ],
              ),
            )
          else if (_result != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '调试结果',
                        style: TextStyle(
                          color: theme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _result!,
                    style: TextStyle(
                      color: theme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
