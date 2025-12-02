import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/escape_record.dart';
import '../providers/record_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/record_card.dart';
import '../widgets/empty_state.dart';
import 'record_form_screen.dart';
import 'record_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('방탈출 다이어리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _navigateToSearch(context),
            tooltip: '검색',
          ),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: '테마 변경',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigateToSettings(context),
            tooltip: '설정',
          ),
        ],
      ),
      body: Consumer<RecordProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.records.isEmpty) {
            return EmptyState(
              icon: Icons.lock_open_outlined,
              title: '아직 기록이 없습니다',
              description: '첫 번째 방탈출 기록을 추가해보세요!',
              action: FilledButton.icon(
                onPressed: () => _navigateToAddRecord(context),
                icon: const Icon(Icons.add),
                label: const Text('기록 추가'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadRecords(),
            child: CustomScrollView(
              slivers: [
                // 통계 헤더
                SliverToBoxAdapter(
                  child: _buildStatisticsHeader(context, provider.statistics),
                ),

                // 기록 목록
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = provider.records[index];
                        return RecordCard(
                          record: record,
                          onTap: () => _navigateToDetail(context, record),
                          onLongPress: () => _showRecordOptions(context, record),
                        );
                      },
                      childCount: provider.records.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddRecord(context),
        icon: const Icon(Icons.add),
        label: const Text('기록 추가'),
      ),
    );
  }

  Widget _buildStatisticsHeader(
      BuildContext context, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final totalCount = stats['totalCount'] ?? 0;
    final clearedCount = stats['clearedCount'] ?? 0;
    final clearRate = stats['clearRate'] ?? 0.0;
    final avgRating = stats['averageRating'] ?? 0.0;

    if (totalCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (통계 타이틀 + 상세보기 버튼)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '통계',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToStatistics(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '상세보기',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 통계 정보
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, '총 기록', '$totalCount회'),
                    _buildStatItem(context, '탈출 성공', '$clearedCount회'),
                    _buildStatItem(
                        context, '탈출률', '${clearRate.toStringAsFixed(1)}%'),
                    _buildStatItem(
                      context,
                      '평균 평점',
                      avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, '총 기록', '$totalCount회'),
                      _buildStatItem(context, '탈출 성공', '$clearedCount회'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          context, '탈출률', '${clearRate.toStringAsFixed(1)}%'),
                      _buildStatItem(
                        context,
                        '평균 평점',
                        avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                      ),
                    ],
                  ),
                ],
              );
            },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToAddRecord(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RecordFormScreen(),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, EscapeRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordDetailScreen(record: record),
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToStatistics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
      ),
    );
  }

  void _showRecordOptions(BuildContext context, EscapeRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RecordFormScreen(record: record),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red[400]),
              title: Text('삭제', style: TextStyle(color: Colors.red[400])),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, record);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EscapeRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text('"${record.themeName}" 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              context.read<RecordProvider>().deleteRecord(record.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('기록이 삭제되었습니다')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
