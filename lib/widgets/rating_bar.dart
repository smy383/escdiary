import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final String label;
  final double rating;
  final ValueChanged<double>? onRatingChanged;
  final bool readOnly;
  final double iconSize;

  const RatingBar({
    super.key,
    required this.label,
    required this.rating,
    this.onRatingChanged,
    this.readOnly = false,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            final isFilled = rating >= starValue;
            final isHalf = rating >= starValue - 0.5 && rating < starValue;

            return GestureDetector(
              onTap: readOnly
                  ? null
                  : () => onRatingChanged?.call(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isFilled
                      ? Icons.star_rounded
                      : isHalf
                          ? Icons.star_half_rounded
                          : Icons.star_border_rounded,
                  color: isFilled || isHalf
                      ? Colors.amber
                      : theme.colorScheme.outline,
                  size: iconSize,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class RatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: Colors.amber,
          size: size,
        ),
        if (showValue) ...[
          const SizedBox(width: 2),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '-',
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
