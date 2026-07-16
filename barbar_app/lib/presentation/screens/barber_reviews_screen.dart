import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/barber_repository.dart';
import '../bloc/review/review_bloc.dart';
import '../bloc/review/review_event.dart';
import '../bloc/review/review_state.dart';
import '../widgets/glass_card.dart';

class BarberReviewsScreen extends StatefulWidget {
  const BarberReviewsScreen({super.key});

  @override
  State<BarberReviewsScreen> createState() => _BarberReviewsScreenState();
}

class _BarberReviewsScreenState extends State<BarberReviewsScreen> {
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final repo = context.read<BarberRepository>();
      final dashboard = await repo.getDashboard();
      final barber = dashboard['barber'] as Map<String, dynamic>? ?? {};
      _shopId = barber['id'] as String?;
      if (_shopId != null && mounted) {
        context.read<ReviewBloc>().add(FetchPublicReviews(shopId: _shopId!));
      }
    } catch (_) {}
  }

  void _showReplyDialog(String reviewId) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Reply to Review'),
        content: TextField(
          controller: replyController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write your reply...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (replyController.text.isNotEmpty) {
                context.read<ReviewBloc>().add(ReplyToReview(
                  reviewId: reviewId,
                  reply: replyController.text,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Reply', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REVIEWS & RATINGS')),
      body: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
            if (_shopId != null) {
              context.read<ReviewBloc>().add(FetchPublicReviews(shopId: _shopId!));
            }
          } else if (state is ReviewFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is PublicReviewsLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRatingSummary(state.summary),
                  const SizedBox(height: 24),
                  const Text('ALL REVIEWS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  if (state.reviews.isEmpty)
                    const Text('No reviews yet', style: TextStyle(color: AppColors.textSecondary))
                  else
                    ...state.reviews.map((review) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (i) => Icon(
                                i < (review.shopRating ?? 0) ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )),
                              const SizedBox(width: 8),
                              Text((review.shopRating ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review.comment, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            'By ${review.customerName}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          if (review.reply != null && review.reply!.message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.reply, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(review.reply!.message, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showReplyDialog(review.id),
                            icon: const Icon(LucideIcons.reply, size: 14),
                            label: const Text('Reply', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            );
          }

          return const Center(child: Text('Pull down to refresh'));
        },
      ),
    );
  }

  Widget _buildRatingSummary(dynamic summary) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            summary.avgRating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Icon(
              i < summary.avgRating.round() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            )),
          ),
          const SizedBox(height: 4),
          Text('${summary.totalReviews} reviews', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...[5, 4, 3, 2, 1].map((stars) {
            int count = 0;
            if (stars == 5) count = summary.distribution.star5;
            else if (stars == 4) count = summary.distribution.star4;
            else if (stars == 3) count = summary.distribution.star3;
            else if (stars == 2) count = summary.distribution.star2;
            else count = summary.distribution.star1;
            final pct = summary.totalReviews > 0 ? count / summary.totalReviews : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('$stars', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.border,
                        color: AppColors.primary,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
