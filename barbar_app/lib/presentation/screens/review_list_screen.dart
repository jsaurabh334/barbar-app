import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/review_model.dart';
import '../../domain/repositories/review_repository.dart';
import '../bloc/review/review_bloc.dart';
import '../bloc/review/review_event.dart';
import '../bloc/review/review_state.dart';
import '../widgets/review_card.dart';
import '../widgets/review_summary_card.dart';

class ReviewListScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ReviewListScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  String _sortBy = 'newest';
  final _scrollController = ScrollController();
  int _page = 1;

  void _onReport(ReviewModel review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Report Review'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Why are you reporting this review? (min 10 chars)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.length < 10) return;
              try {
                await context.read<ReviewRepository>().reportReview(review.id, reason);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review reported. We will review it shortly.')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchReviews() {
    context.read<ReviewBloc>().add(
      FetchPublicReviews(
        shopId: widget.shopId,
        page: _page,
        sort: _sortBy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.shopName} Reviews')),
      body: Column(
        children: [
          BlocBuilder<ReviewBloc, ReviewState>(
            builder: (context, state) {
              if (state is PublicReviewsLoaded) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ReviewSummaryCard(
                    summary: state.summary,
                    onViewAll: null,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Sort:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'highest', child: Text('Highest Rated', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'lowest', child: Text('Lowest Rated', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _sortBy = val;
                        _page = 1;
                      });
                      _fetchReviews();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ReviewBloc, ReviewState>(
              builder: (context, state) {
                if (state is ReviewLoading && _page == 1) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (state is PublicReviewsLoaded) {
                  if (state.reviews.isEmpty) {
                    return const Center(child: Text('No reviews yet', style: TextStyle(color: AppColors.textMuted)));
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.reviews.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.reviews.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }
                      return ReviewCard(
                        review: state.reviews[index],
                        onReport: () => _onReport(state.reviews[index]),
                      );
                    },
                  );
                }
                if (state is ReviewFailure) {
                  return Center(child: Text('Error: ${state.error}', style: const TextStyle(color: AppColors.error)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
