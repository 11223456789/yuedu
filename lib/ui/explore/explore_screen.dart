import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/strings.dart';
import '../../data/database/daos/book_source_dao.dart';
import '../../data/repositories/book_source_repository.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import 'explore_kind_screen.dart';

/// 发现页面 - 复刻legado的ExploreFragment
/// 按书源分组展示，每个书源下显示其发现分类
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  List<BookSource> _enabledSources = [];
  Map<String, List<ExploreKind>> _sourceKinds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() {
      _isLoading = true;
    });

    final repository = ref.read(bookSourceRepositoryProvider);
    final sources = await repository.getAllSources();

    // 只获取启用了发现功能的书源
    _enabledSources = sources
        .where((s) => s.enabled && s.enabledExplore && s.exploreUrl != null && s.exploreUrl!.isNotEmpty)
        .toList();

    // 解析每个书源的发现分类
    _sourceKinds = {};
    for (final source in _enabledSources) {
      final kinds = _parseExploreKinds(source);
      if (kinds.isNotEmpty) {
        _sourceKinds[source.bookSourceUrl] = kinds;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// 解析书源的发现分类
  /// 支持两种格式：
  /// 1. 简单格式："分类名::URL||分类名2::URL2"
  /// 2. JSON格式：包含title和url的对象数组
  List<ExploreKind> _parseExploreKinds(BookSource source) {
    final exploreUrl = source.exploreUrl;
    if (exploreUrl == null || exploreUrl.isEmpty) return [];

    final kinds = <ExploreKind>[];

    try {
      // 尝试解析为JSON
      final decoded = jsonDecode(exploreUrl);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            kinds.add(ExploreKind(
              title: item['title']?.toString() ?? '',
              url: item['url']?.toString() ?? '',
              style: item['style']?.toString(),
            ));
          }
        }
        return kinds;
      }
    } catch (e) {
      // 不是JSON，使用简单格式解析
    }

    // 简单格式解析："分类名::URL||分类名2::URL2"
    final lines = exploreUrl.split('||');
    for (final line in lines) {
      final parts = line.split('::');
      if (parts.length >= 2) {
        kinds.add(ExploreKind(
          title: parts[0].trim(),
          url: parts[1].trim(),
        ));
      }
    }

    return kinds;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '发现',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSources,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.primary),
            )
          : _enabledSources.isEmpty
              ? _buildEmptyView(theme)
              : _buildExploreList(theme),
    );
  }

  Widget _buildEmptyView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 64,
            color: theme.subText,
          ),
          const SizedBox(height: 16),
          Text(
            '没有启用的发现书源',
            style: TextStyle(
              color: theme.subText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请在书源管理中启用带发现功能的书源',
            style: TextStyle(
              color: theme.subText.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreList(AppThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadSources,
      color: theme.primary,
      backgroundColor: theme.surface,
      child: ListView.builder(
        itemCount: _enabledSources.length,
        itemBuilder: (context, index) {
          final source = _enabledSources[index];
          final kinds = _sourceKinds[source.bookSourceUrl] ?? [];

          if (kinds.isEmpty) return const SizedBox.shrink();

          return _buildSourceSection(source, kinds, theme);
        },
      ),
    );
  }

  Widget _buildSourceSection(BookSource source, List<ExploreKind> kinds, AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 书源标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  source.bookSourceName,
                  style: TextStyle(
                    color: theme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (source.bookSourceGroup != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            ],
          ),
        ),
        // 分类网格
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kinds.map((kind) => _buildKindChip(source, kind, theme)).toList(),
          ),
        ),
        const GoldDivider(),
      ],
    );
  }

  Widget _buildKindChip(BookSource source, ExploreKind kind, AppThemeData theme) {
    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExploreKindScreen(
                source: source,
                kind: kind,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            kind.title,
            style: TextStyle(
              color: theme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// 发现分类数据类
class ExploreKind {
  final String title;
  final String url;
  final String? style;

  ExploreKind({
    required this.title,
    required this.url,
    this.style,
  });
}
