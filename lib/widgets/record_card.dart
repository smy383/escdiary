import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/escape_record.dart';
import 'hexagon_chart.dart'; // PentagonChart 포함

class RecordCard extends StatelessWidget {
  final EscapeRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const RecordCard({
    super.key,
    required this.record,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 테마명, 탈출 여부
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.themeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.fullLocation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 12),

              // 정보 2x2 그리드 + 차트
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽: 2x2 정보 그리드
                  Expanded(
                    child: Row(
                      children: [
                        // 첫번째 열: 날짜, 남은시간
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoItem(
                                context,
                                Icons.calendar_today_outlined,
                                dateFormat.format(record.playDate),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoItem(
                                context,
                                Icons.hourglass_bottom,
                                record.remainingTime != null
                                    ? '${record.remainingTime} 남음'
                                    : '-',
                              ),
                            ],
                          ),
                        ),
                        // 두번째 열: 인원, 제한시간
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoItem(
                                context,
                                Icons.group_outlined,
                                '${record.playerCount}명',
                              ),
                              const SizedBox(height: 8),
                              _buildInfoItem(
                                context,
                                Icons.timer_outlined,
                                '${record.playTime}분',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽: 차트 + 만족도
                  if (_hasAnyRating()) ...[
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        PentagonChart(
                          interior: record.ratingInterior,
                          satisfaction: record.ratingSatisfaction,
                          puzzle: record.ratingPuzzle,
                          story: record.ratingStory,
                          production: record.ratingProduction,
                          size: 56,
                        ),
                        const SizedBox(height: 4),
                        if (record.ratingSatisfaction > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                record.ratingSatisfaction.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: record.isCleared
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isCleared
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            record.isCleared ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: record.isCleared ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            record.isCleared ? '탈출 성공' : '탈출 실패',
            style: theme.textTheme.labelSmall?.copyWith(
              color: record.isCleared ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  bool _hasAnyRating() {
    return record.ratingInterior > 0 ||
        record.ratingSatisfaction > 0 ||
        record.ratingPuzzle > 0 ||
        record.ratingStory > 0 ||
        record.ratingProduction > 0;
  }
}
