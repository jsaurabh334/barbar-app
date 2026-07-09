import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RatingBar extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;
  final bool showLabel;

  static const labels = {
    5: 'Excellent',
    4: 'Good',
    3: 'Average',
    2: 'Poor',
    1: 'Very Bad',
  };

  const RatingBar({
    super.key,
    this.rating = 0,
    this.size = 32,
    this.onChanged,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? null : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= rating;
              return GestureDetector(
                onTap: onChanged != null ? () => onChanged!(starValue) : null,
                child: Padding(
                  padding: EdgeInsets.all(size * 0.1),
                  child: Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    color: isFilled ? AppColors.warning : AppColors.textMuted,
                    size: size,
                  ),
                ),
              );
            }),
          ),
          if (showLabel && rating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                labels[rating] ?? '',
                style: TextStyle(
                  fontSize: size * 0.4,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
