import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/escape_record.dart';
import '../models/detail_memo.dart';
import '../providers/record_provider.dart';
import '../widgets/hexagon_chart.dart';
import 'record_form_screen.dart';

class RecordDetailScreen extends StatelessWidget {
  final EscapeRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');

    // Provider에서 최신 데이터 가져오기
    final provider = context.watch<RecordProvider>();
    final currentRecord = provider.getRecordById(record.id) ?? record;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEdit(context, currentRecord),
            tooltip: '수정',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            onPressed: () => _confirmDelete(context, currentRecord),
            tooltip: '삭제',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentRecord.themeName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(context, currentRecord.isCleared),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentRecord.fullLocation,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),

                    // 플레이 정보
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildInfoChip(
                          context,
                          Icons.calendar_today,
                          dateFormat.format(currentRecord.playDate),
                        ),
                        _buildInfoChip(
                          context,
                          Icons.group,
                          '${currentRecord.playerCount}명',
                        ),
                        _buildInfoChip(
                          context,
                          Icons.timer,
                          '제한시간 ${currentRecord.playTime}분',
                        ),
                        if (currentRecord.hintCount != null)
                          _buildInfoChip(
                            context,
                            Icons.lightbulb,
                            '힌트 ${currentRecord.hintCount}회',
                          ),
                        if (currentRecord.clearTime != null)
                          _buildInfoChip(
                            context,
                            currentRecord.clearTimeType == ClearTimeType.remaining
                                ? Icons.hourglass_bottom
                                : Icons.timer,
                            currentRecord.clearTimeType == ClearTimeType.remaining
                                ? '남은 시간 ${currentRecord.clearTime}'
                                : '걸린 시간 ${currentRecord.clearTime}',
                          ),
                      ],
                    ),

                    // 평균 평점
                    if (currentRecord.averageRating > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '평균 ${currentRecord.averageRating.toStringAsFixed(1)}점',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 상세 평점
            if (_hasAnyRating(currentRecord)) ...[
              const SizedBox(height: 20),
              _buildSectionTitle(context, '상세 평점'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 큰 육각형 차트
                      _buildLargeHexagonChart(context, currentRecord),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      // 상세 평점 행
                      _buildRatingRow(context, '인테리어', currentRecord.ratingInterior),
                      _buildRatingRow(context, '만족도', currentRecord.ratingSatisfaction),
                      _buildRatingRow(context, '문제', currentRecord.ratingPuzzle),
                      _buildRatingRow(context, '스토리', currentRecord.ratingStory),
                      _buildRatingRow(context, '연출', currentRecord.ratingProduction),
                    ],
                  ),
                ),
              ),
            ],

            // 메모 섹션 (탭)
            if (_hasAnyMemo(currentRecord)) ...[
              const SizedBox(height: 20),
              _buildMemoSection(context, currentRecord),
            ],

            // 메타 정보
            const SizedBox(height: 24),
            Text(
              '생성: ${DateFormat('yyyy.MM.dd HH:mm').format(currentRecord.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              '수정: ${DateFormat('yyyy.MM.dd HH:mm').format(currentRecord.updatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool _hasAnyRating(EscapeRecord record) {
    return record.ratingInterior > 0 ||
        record.ratingSatisfaction > 0 ||
        record.ratingPuzzle > 0 ||
        record.ratingStory > 0 ||
        record.ratingProduction > 0;
  }

  bool _hasAnyMemo(EscapeRecord record) {
    return (record.content != null && record.content!.isNotEmpty) ||
        (record.detailMemos != null && record.detailMemos!.isNotEmpty);
  }

  Widget _buildMemoSection(BuildContext context, EscapeRecord record) {
    final theme = Theme.of(context);
    final hasSimpleMemo = record.content != null && record.content!.isNotEmpty;
    final hasDetailMemos = record.detailMemos != null && record.detailMemos!.isNotEmpty;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              tabs: const [
                Tab(text: '간단 메모'),
                Tab(text: '상세 메모'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _calculateMemoHeight(record),
            child: TabBarView(
              children: [
                // 간단 메모 탭
                hasSimpleMemo
                    ? Card(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            record.content!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          '간단 메모가 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                // 상세 메모 탭
                hasDetailMemos
                    ? SingleChildScrollView(
                        child: Column(
                          children: record.detailMemos!
                              .map((memo) => _buildDetailMemoCard(context, memo))
                              .toList(),
                        ),
                      )
                    : Center(
                        child: Text(
                          '상세 메모가 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMemoHeight(EscapeRecord record) {
    // 기본 높이
    double height = 150;

    // 간단 메모 길이에 따라 조정
    if (record.content != null && record.content!.isNotEmpty) {
      final lines = record.content!.split('\n').length;
      height = math.max(height, lines * 24.0 + 50);
    }

    // 상세 메모 개수에 따라 조정
    if (record.detailMemos != null && record.detailMemos!.isNotEmpty) {
      height = math.max(height, record.detailMemos!.length * 120.0);
    }

    return math.min(height, 400); // 최대 400
  }

  Widget _buildDetailMemoCard(BuildContext context, DetailMemo memo) {
    final theme = Theme.of(context);

    Color getTypeColor() {
      switch (memo.type) {
        case MemoType.story:
          return Colors.blue;
        case MemoType.production:
          return Colors.purple;
        case MemoType.puzzle:
          return Colors.orange;
        case MemoType.answer:
          return Colors.green;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: getTypeColor().withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getTypeColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    memo.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: getTypeColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              memo.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isCleared) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCleared
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCleared
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCleared ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isCleared ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isCleared ? '탈출 성공' : '탈출 실패',
            style: TextStyle(
              color: isCleared ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
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

  Widget _buildLargeHexagonChart(BuildContext context, EscapeRecord record) {
    final labels = ['인테리어', '만족도', '문제', '스토리', '연출'];
    final values = [
      record.ratingInterior,
      record.ratingSatisfaction,
      record.ratingPuzzle,
      record.ratingStory,
      record.ratingProduction,
    ];

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 육각형 차트
              HexagonChart(
                interior: record.ratingInterior,
                satisfaction: record.ratingSatisfaction,
                puzzle: record.ratingPuzzle,
                story: record.ratingStory,
                production: record.ratingProduction,
                horror: record.ratingHorror,
                size: 140,
              ),
              // 레이블들 (5개 꼭짓점)
              for (int i = 0; i < 5; i++)
                _buildPositionedLabel(
                  context,
                  labels[i],
                  values[i],
                  i,
                  100,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionedLabel(
    BuildContext context,
    String label,
    double value,
    int index,
    double radius,
  ) {
    final theme = Theme.of(context);
    // 각도 계산: 위(12시)에서 시작, 시계방향 (5각형: 72도 간격)
    final angle = (index * 72 - 90) * math.pi / 180;
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (value > 0)
            Text(
              value.toStringAsFixed(1),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, String label, double rating) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                final isFilled = rating >= starValue;
                return Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled ? Colors.amber : theme.colorScheme.outline,
                  size: 22,
                );
              }),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              rating > 0 ? rating.toStringAsFixed(1) : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: rating > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, EscapeRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordFormScreen(record: record),
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
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Detail screen
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
