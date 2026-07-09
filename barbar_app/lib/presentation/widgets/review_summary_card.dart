import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/review_model.dart';
import 'rating_bar.dart';

class ReviewSummaryCard extends StatelessWidget {
  final ReviewSummaryModel summary;
  final VoidCallback? onViewAll;

  const ReviewSummaryCard({
    super.key,
    required this.summary,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: Text('No reviews yet', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  RatingBar(rating: summary.avgRating.round(), size: 18),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.totalReviews} reviews',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _buildDistributionBar('5', summary.distribution.star5),
                    _buildDistributionBar('4', summary.distribution.star4),
                    _buildDistributionBar('3', summary.distribution.star3),
                    _buildDistributionBar('2', summary.distribution.star2),
                    _buildDistributionBar('1', summary.distribution.star1),
                  ],
                ),
              ),
            ],
          ),
          if (onViewAll != null && summary.totalReviews > 0) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewAll,
                child: const Text('View All Reviews →', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count) {
    final pct = summary.totalReviews > 0 ? count / summary.totalReviews : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
