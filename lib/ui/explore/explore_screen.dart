import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/strings.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '发现',
      ),
      body: Container(
        color: theme.background,
        child: ListView(
          children: [
            _buildSectionHeader('热门推荐', theme),
            _buildExploreCategories(theme),
            const GoldDivider(),
            _buildSectionHeader('书源分类', theme),
            _buildSourceCategories(theme),
            const GoldDivider(),
            _buildSectionHeader('排行榜', theme),
            _buildRankings(theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          color: theme.primary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExploreCategories(AppThemeData theme) {
    final categories = [
      {'icon': Icons.favorite, 'name': '玄幻', 'color': Colors.red},
      {'icon': Icons.star, 'name': '仙侠', 'color': Colors.orange},
      {'icon': Icons.public, 'name': '都市', 'color': Colors.blue},
      {'icon': Icons.history, 'name': '历史', 'color': Colors.green},
      {'icon': Icons.science, 'name': '科幻', 'color': Colors.purple},
      {'icon': Icons.sports, 'name': '游戏', 'color': Colors.teal},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryItem(category, theme);
        },
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, AppThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category['icon'] as IconData,
                size: 32,
                color: theme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                category['name'] as String,
                style: TextStyle(
                  color: theme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCategories(AppThemeData theme) {
    final sources = [
      {'name': '笔趣阁', 'count': 12580},
      {'name': '起点中文', 'count': 8956},
      {'name': '纵横中文', 'count': 6723},
      {'name': '17K小说', 'count': 5421},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sources.map((source) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.source,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source['name'] as String,
                              style: TextStyle(
                                color: theme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${source['count']} 本书',
                              style: TextStyle(
                                color: theme.subText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.subText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankings(AppThemeData theme) {
    final rankings = [
      {'title': '热搜榜', 'books': ['斗破苍穹', '完美世界', '遮天']},
      {'title': '收藏榜', 'books': ['凡人修仙传', '仙逆', '求魔']},
      {'title': '推荐榜', 'books': ['诡秘之主', '全职高手', '盗墓笔记']},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: rankings.map((ranking) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: theme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ranking['title'] as String,
                            style: TextStyle(
                              color: theme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(ranking['books'] as List<String>).asMap().entries.map((entry) {
                        final index = entry.key;
                        final book = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: index < 3
                                      ? theme.primary.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: index < 3 ? theme.primary : theme.subText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                book,
                                style: TextStyle(
                                  color: theme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
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
