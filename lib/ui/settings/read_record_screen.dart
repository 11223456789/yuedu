import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/daos/read_record_dao.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';

class ReadRecordScreen extends ConsumerStatefulWidget {
  const ReadRecordScreen({super.key});

  @override
  ConsumerState<ReadRecordScreen> createState() => _ReadRecordScreenState();
}

class _ReadRecordScreenState extends ConsumerState<ReadRecordScreen> {
  final ReadRecordDao _recordDao = ReadRecordDao();
  Map<String, int> _totalStats = {};
  Map<String, dynamic> _weekStats = {};
  DailyReadStats _todayStats = DailyReadStats(date: '');
  List<ReadRecord> _records = [];
  List<DailyReadStats> _dailyStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final totalStats = await _recordDao.getTotalStats();
    final weekStats = await _recordDao.getWeekStats();
    final todayStats = await _recordDao.getTodayStats();
    final records = await _recordDao.getAllRecords();
    final dailyStats = await _recordDao.getDailyStats();

    // 按阅读时长排序
    records.sort((a, b) => b.readTime.compareTo(a.readTime));

    if (mounted) {
      setState(() {
        _totalStats = totalStats;
        _weekStats = weekStats;
        _todayStats = todayStats;
        _records = records;
        _dailyStats = dailyStats..sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else if (minutes > 0) {
      return '${minutes}分钟';
    } else {
      return '${seconds}秒';
    }
  }

  String _formatWords(int words) {
    if (words >= 10000) {
      return '${(words / 10000).toStringAsFixed(1)}万字';
    } else if (words >= 1000) {
      return '${(words / 1000).toStringAsFixed(1)}千字';
    } else {
      return '$words字';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '阅读统计',
        actions: [
          TextButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: theme.surface,
                  title: Text(
                    '确认清空',
                    style: TextStyle(color: theme.onSurface),
                  ),
                  content: Text(
                    '确定要清空所有阅读记录吗？此操作不可恢复。',
                    style: TextStyle(color: theme.subText),
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
                        Navigator.pop(context);
                        await _recordDao.clearAll();
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('阅读记录已清空')),
                          );
                        }
                      },
                      child: Text(
                        '确定',
                        style: TextStyle(color: theme.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              '清空',
              style: TextStyle(color: theme.error),
            ),
          ),
        ],
      ),
      body: Container(
        color: theme.background,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: theme.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: theme.primary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTodayCard(theme),
                    const SizedBox(height: 16),
                    _buildTotalStatsCard(theme),
                    const SizedBox(height: 16),
                    _buildWeekStatsCard(theme),
                    const SizedBox(height: 16),
                    _buildDailyStatsCard(theme),
                    const SizedBox(height: 16),
                    _buildBookListCard(theme),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTodayCard(AppThemeData theme) {
    return Card(
      color: theme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日阅读',
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '时长',
                  _formatDuration(_todayStats.readTime),
                  theme,
                ),
                _buildStatItem(
                  '字数',
                  _formatWords(_todayStats.readWords),
                  theme,
                ),
                _buildStatItem(
                  '次数',
                  '${_todayStats.readCount}次',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalStatsCard(AppThemeData theme) {
    return Card(
      color: theme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '累计阅读',
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '总时长',
                  _formatDuration(_totalStats['totalTime'] ?? 0),
                  theme,
                ),
                _buildStatItem(
                  '总字数',
                  _formatWords(_totalStats['totalWords'] ?? 0),
                  theme,
                ),
                _buildStatItem(
                  '书籍',
                  '${_totalStats['bookCount'] ?? 0}本',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStatsCard(AppThemeData theme) {
    return Card(
      color: theme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周阅读',
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '总时长',
                  _formatDuration(_weekStats['totalTime'] ?? 0),
                  theme,
                ),
                _buildStatItem(
                  '天数',
                  '${_weekStats['daysRead'] ?? 0}天',
                  theme,
                ),
                _buildStatItem(
                  '日均',
                  _formatDuration(_weekStats['averageTime'] ?? 0),
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStatsCard(AppThemeData theme) {
    if (_dailyStats.isEmpty || _dailyStats.every((s) => s.readTime == 0)) {
      return const SizedBox.shrink();
    }

    return Card(
      color: theme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近7天',
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _dailyStats.take(7).toList().reversed.map((stat) {
                  final maxTime = _dailyStats
                      .take(7)
                      .map((s) => s.readTime)
                      .reduce((a, b) => a > b ? a : b);
                  final height = maxTime > 0
                      ? (stat.readTime / maxTime * 100).clamp(10.0, 100.0)
                      : 10.0;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: stat.readTime > 0
                                  ? theme.primary
                                  : theme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stat.date.substring(5), // 显示 MM-dd
                            style: TextStyle(
                              color: theme.subText,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookListCard(AppThemeData theme) {
    if (_records.isEmpty) {
      return Card(
        color: theme.surface,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 48,
                  color: theme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无阅读记录',
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      color: theme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '阅读排行',
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const GoldDivider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _records.take(10).length,
            separatorBuilder: (context, index) => const GoldDivider(),
            itemBuilder: (context, index) {
              final record = _records[index];
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: index < 3
                        ? theme.primary.withOpacity(0.2)
                        : theme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index < 3 ? theme.primary : theme.subText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  record.bookName,
                  style: TextStyle(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_formatDuration(record.readTime)} · ${_formatWords(record.readWords)}',
                  style: TextStyle(color: theme.subText, fontSize: 12),
                ),
                trailing: Text(
                  '${record.readCount}次',
                  style: TextStyle(color: theme.subText, fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.subText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
