import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/record_provider.dart';
import '../models/escape_record.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordProvider>();
    final records = provider.records;

    if (records.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('상세 통계')),
        body: const Center(
          child: Text('기록이 없습니다'),
        ),
      );
    }

    final stats = _calculateAllStats(records);

    return Scaffold(
      appBar: AppBar(title: const Text('상세 통계')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기본 통계
            _buildSectionTitle(context, '기본 통계'),
            const SizedBox(height: 12),
            _buildBasicStatsCard(context, stats),

            const SizedBox(height: 24),

            // 월별 통계
            _buildSectionTitle(context, '월별 플레이 현황'),
            const SizedBox(height: 12),
            _buildMonthlyChart(context, stats),

            const SizedBox(height: 24),

            // 요일별 통계
            _buildSectionTitle(context, '요일별 플레이 빈도'),
            const SizedBox(height: 12),
            _buildWeekdayChart(context, stats),

            const SizedBox(height: 24),

            // 평점 통계
            _buildSectionTitle(context, '평점 통계'),
            const SizedBox(height: 12),
            _buildRatingStatsCard(context, stats),

            const SizedBox(height: 24),

            // 플레이 패턴
            _buildSectionTitle(context, '플레이 패턴'),
            const SizedBox(height: 12),
            _buildPlayPatternCard(context, stats),

            const SizedBox(height: 24),

            // 제한시간 분포
            _buildSectionTitle(context, '제한시간 분포'),
            const SizedBox(height: 12),
            _buildPlayTimeDistribution(context, stats),

            const SizedBox(height: 24),

            // 연속 기록
            _buildSectionTitle(context, '연속 기록'),
            const SizedBox(height: 12),
            _buildStreakCard(context, stats),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateAllStats(List<EscapeRecord> records) {
    // 기본 통계
    final totalCount = records.length;
    final clearedCount = records.where((r) => r.isCleared).length;
    final failedCount = totalCount - clearedCount;
    final clearRate = totalCount > 0 ? clearedCount / totalCount * 100 : 0.0;
    final totalPlayTime = records.fold<int>(0, (sum, r) => sum + r.playTime);

    // 월별 통계
    final monthlyStats = <String, int>{};
    for (final record in records) {
      final key = DateFormat('yyyy-MM').format(record.playDate);
      monthlyStats[key] = (monthlyStats[key] ?? 0) + 1;
    }

    // 요일별 통계
    final weekdayStats = List.filled(7, 0);
    for (final record in records) {
      final weekday = record.playDate.weekday - 1; // 0 = 월요일
      weekdayStats[weekday]++;
    }

    // 평점 통계
    final ratingRecords = records.where((r) =>
        r.ratingInterior > 0 ||
        r.ratingSatisfaction > 0 ||
        r.ratingPuzzle > 0 ||
        r.ratingStory > 0 ||
        r.ratingProduction > 0).toList();

    double avgInterior = 0, avgSatisfaction = 0, avgPuzzle = 0, avgStory = 0, avgProduction = 0;
    if (ratingRecords.isNotEmpty) {
      final interiorRecords = ratingRecords.where((r) => r.ratingInterior > 0);
      final satisfactionRecords = ratingRecords.where((r) => r.ratingSatisfaction > 0);
      final puzzleRecords = ratingRecords.where((r) => r.ratingPuzzle > 0);
      final storyRecords = ratingRecords.where((r) => r.ratingStory > 0);
      final productionRecords = ratingRecords.where((r) => r.ratingProduction > 0);

      if (interiorRecords.isNotEmpty) {
        avgInterior = interiorRecords.fold<double>(0, (sum, r) => sum + r.ratingInterior) / interiorRecords.length;
      }
      if (satisfactionRecords.isNotEmpty) {
        avgSatisfaction = satisfactionRecords.fold<double>(0, (sum, r) => sum + r.ratingSatisfaction) / satisfactionRecords.length;
      }
      if (puzzleRecords.isNotEmpty) {
        avgPuzzle = puzzleRecords.fold<double>(0, (sum, r) => sum + r.ratingPuzzle) / puzzleRecords.length;
      }
      if (storyRecords.isNotEmpty) {
        avgStory = storyRecords.fold<double>(0, (sum, r) => sum + r.ratingStory) / storyRecords.length;
      }
      if (productionRecords.isNotEmpty) {
        avgProduction = productionRecords.fold<double>(0, (sum, r) => sum + r.ratingProduction) / productionRecords.length;
      }
    }

    // 최고/최저 만족도 테마
    EscapeRecord? highestRated, lowestRated;
    final ratedRecords = records.where((r) => r.ratingSatisfaction > 0).toList();
    if (ratedRecords.isNotEmpty) {
      ratedRecords.sort((a, b) => b.ratingSatisfaction.compareTo(a.ratingSatisfaction));
      highestRated = ratedRecords.first;
      lowestRated = ratedRecords.last;
    }

    // 플레이 패턴
    final avgPlayerCount = records.fold<int>(0, (sum, r) => sum + r.playerCount) / totalCount;
    final hintRecords = records.where((r) => r.hintCount != null).toList();
    final avgHintCount = hintRecords.isNotEmpty
        ? hintRecords.fold<int>(0, (sum, r) => sum + r.hintCount!) / hintRecords.length
        : 0.0;

    // 성공 시 평균 남은 시간
    final clearedWithTime = records.where((r) => r.isCleared && r.remainingTime != null).toList();
    double avgRemainingSeconds = 0;
    if (clearedWithTime.isNotEmpty) {
      int totalSeconds = 0;
      for (final r in clearedWithTime) {
        final parts = r.remainingTime!.split(':');
        if (parts.length == 2) {
          totalSeconds += int.parse(parts[0]) * 60 + int.parse(parts[1]);
        }
      }
      avgRemainingSeconds = totalSeconds / clearedWithTime.length;
    }

    // 제한시간 분포
    final playTimeDistribution = <int, int>{};
    for (final record in records) {
      playTimeDistribution[record.playTime] = (playTimeDistribution[record.playTime] ?? 0) + 1;
    }

    // 연속 기록
    final sortedByDate = List<EscapeRecord>.from(records)
      ..sort((a, b) => a.playDate.compareTo(b.playDate));

    int currentStreak = 0, maxSuccessStreak = 0, maxFailStreak = 0;
    bool? lastResult;

    for (final record in sortedByDate) {
      if (lastResult == null || lastResult == record.isCleared) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }

      if (record.isCleared) {
        maxSuccessStreak = currentStreak > maxSuccessStreak ? currentStreak : maxSuccessStreak;
      } else {
        maxFailStreak = currentStreak > maxFailStreak ? currentStreak : maxFailStreak;
      }
      lastResult = record.isCleared;
    }

    // 이번 달 플레이 횟수
    final now = DateTime.now();
    final thisMonthCount = records.where((r) =>
        r.playDate.year == now.year && r.playDate.month == now.month).length;

    // 연도별 통계
    final yearlyStats = <int, int>{};
    for (final record in records) {
      yearlyStats[record.playDate.year] = (yearlyStats[record.playDate.year] ?? 0) + 1;
    }

    return {
      'totalCount': totalCount,
      'clearedCount': clearedCount,
      'failedCount': failedCount,
      'clearRate': clearRate,
      'totalPlayTime': totalPlayTime,
      'monthlyStats': monthlyStats,
      'weekdayStats': weekdayStats,
      'avgInterior': avgInterior,
      'avgSatisfaction': avgSatisfaction,
      'avgPuzzle': avgPuzzle,
      'avgStory': avgStory,
      'avgProduction': avgProduction,
      'highestRated': highestRated,
      'lowestRated': lowestRated,
      'avgPlayerCount': avgPlayerCount,
      'avgHintCount': avgHintCount,
      'avgRemainingSeconds': avgRemainingSeconds,
      'playTimeDistribution': playTimeDistribution,
      'maxSuccessStreak': maxSuccessStreak,
      'maxFailStreak': maxFailStreak,
      'thisMonthCount': thisMonthCount,
      'yearlyStats': yearlyStats,
    };
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildBasicStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final totalPlayTime = stats['totalPlayTime'] as int;
    final hours = totalPlayTime ~/ 60;
    final minutes = totalPlayTime % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '총 플레이',
                    '${stats['totalCount']}회',
                    Icons.games_outlined,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '성공률',
                    '${(stats['clearRate'] as double).toStringAsFixed(1)}%',
                    Icons.emoji_events_outlined,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '성공',
                    '${stats['clearedCount']}회',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '실패',
                    '${stats['failedCount']}회',
                    Icons.cancel_outlined,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '총 플레이 시간',
                    hours > 0 ? '$hours시간 $minutes분' : '$minutes분',
                    Icons.timer_outlined,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '이번 달',
                    '${stats['thisMonthCount']}회',
                    Icons.calendar_month,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final monthlyStats = stats['monthlyStats'] as Map<String, int>;

    if (monthlyStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('데이터가 없습니다'),
        ),
      );
    }

    // 최근 6개월만 표시
    final sortedKeys = monthlyStats.keys.toList()..sort();
    final recentKeys = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    final maxValue = recentKeys.map((k) => monthlyStats[k]!).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: recentKeys.map((key) {
                  final value = monthlyStats[key]!;
                  final height = maxValue > 0 ? (value / maxValue) * 100 : 0.0;
                  final month = key.split('-')[1];

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$value',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$month월',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
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

  Widget _buildWeekdayChart(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final weekdayStats = stats['weekdayStats'] as List<int>;
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final maxValue = weekdayStats.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final value = weekdayStats[index];
              final height = maxValue > 0 ? (value / maxValue) * 70 : 0.0;
              final isWeekend = index >= 5;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$value',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isWeekend
                            ? Colors.orange
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weekdays[index],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isWeekend ? Colors.orange : null,
                        fontWeight: isWeekend ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final categories = [
      ('인테리어', stats['avgInterior'] as double),
      ('만족도', stats['avgSatisfaction'] as double),
      ('문제', stats['avgPuzzle'] as double),
      ('스토리', stats['avgStory'] as double),
      ('연출', stats['avgProduction'] as double),
    ];

    final highestRated = stats['highestRated'] as EscapeRecord?;
    final lowestRated = stats['lowestRated'] as EscapeRecord?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리별 평균
            ...categories.map((cat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(cat.$1, style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: cat.$2 / 5,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: _getRatingColor(cat.$2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 35,
                    child: Text(
                      cat.$2 > 0 ? cat.$2.toStringAsFixed(1) : '-',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            )),

            if (highestRated != null && lowestRated != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.thumb_up, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('최고 만족', style: theme.textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          highestRated.themeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${highestRated.ratingSatisfaction.toStringAsFixed(1)}점',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.thumb_down, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('최저 만족', style: theme.textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lowestRated.themeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${lowestRated.ratingSatisfaction.toStringAsFixed(1)}점',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    if (rating > 0) return Colors.red;
    return Colors.grey;
  }

  Widget _buildPlayPatternCard(BuildContext context, Map<String, dynamic> stats) {
    final avgRemainingSeconds = stats['avgRemainingSeconds'] as double;
    final mins = (avgRemainingSeconds / 60).floor();
    final secs = (avgRemainingSeconds % 60).floor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPatternItem(
                    context,
                    '평균 인원',
                    '${(stats['avgPlayerCount'] as double).toStringAsFixed(1)}명',
                    Icons.group,
                  ),
                ),
                Expanded(
                  child: _buildPatternItem(
                    context,
                    '평균 힌트',
                    '${(stats['avgHintCount'] as double).toStringAsFixed(1)}회',
                    Icons.lightbulb,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPatternItem(
                    context,
                    '성공 시 평균 남은 시간',
                    avgRemainingSeconds > 0 ? '$mins:${secs.toString().padLeft(2, '0')}' : '-',
                    Icons.hourglass_bottom,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayTimeDistribution(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final distribution = stats['playTimeDistribution'] as Map<int, int>;

    if (distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('데이터가 없습니다'),
        ),
      );
    }

    final sortedKeys = distribution.keys.toList()..sort();
    final total = distribution.values.reduce((a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sortedKeys.map((time) {
            final count = distribution[time]!;
            final percentage = count / total;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text('$time분', style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$count회 (${(percentage * 100).toStringAsFixed(0)}%)',
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.green, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${stats['maxSuccessStreak']}회',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '최장 연속 성공',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.trending_down, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${stats['maxFailStreak']}회',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    '최장 연속 실패',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
