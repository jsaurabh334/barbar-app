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
  final List<Map<String, dynamic>>? staffMembers;

  const ReviewListScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    this.staffMembers,
  });

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  String _sortBy = 'newest';
  String? _selectedStaffId;
  final _scrollController = ScrollController();
  int _page = 1;

  void _onReport(ReviewModel review) {
    String? selectedReason;
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Report Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this review?',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...['spam', 'fake', 'abusive', 'wrong_information', 'other'].map((r) {
                final label = {
                  'spam': 'Spam',
                  'fake': 'Fake Review',
                  'abusive': 'Abusive',
                  'wrong_information': 'Wrong Information',
                  'other': 'Other',
                }[r]!;
                return RadioListTile<String>(
                  value: r,
                  groupValue: selectedReason,
                  title: Text(label, style: const TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setDialogState(() => selectedReason = val),
                );
              }),
              if (selectedReason == 'other')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: customController,
                    maxLines: 2,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      try {
                        await context.read<ReviewRepository>().reportReview(
                          review.id,
                          selectedReason!,
                          customReason: selectedReason == 'other' ? customController.text.trim() : null,
                        );
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
        staffId: _selectedStaffId,
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
          // Staff filter chips
          if (widget.staffMembers != null && widget.staffMembers!.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip('All', null),
                  ...widget.staffMembers!.map((s) {
                    final name = s['name'] as String? ?? 'Staff';
                    final id = s['id'] as String?;
                    return _filterChip(name, id);
                  }),
                ],
              ),
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

  Widget _filterChip(String label, String? staffId) {
    final isSelected = _selectedStaffId == staffId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        onSelected: (val) {
          setState(() {
            _selectedStaffId = staffId;
            _page = 1;
          });
          _fetchReviews();
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
