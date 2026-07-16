import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/data/models/review_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

class AdminReviewModerationScreen extends StatefulWidget {
  final AdminRepository adminRepository;

  const AdminReviewModerationScreen({super.key, required this.adminRepository});

  @override
  State<AdminReviewModerationScreen> createState() => _AdminReviewModerationScreenState();
}

class _AdminReviewModerationScreenState extends State<AdminReviewModerationScreen> {
  String _statusFilter = '';
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasMore && !_isLoading) {
      _page++;
      _fetchReviews(isLoadMore: true);
    }
  }

  Future<void> _fetchReviews({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() => _isLoading = true);
    }
    try {
      final result = await widget.adminRepository.getAllReviews(
        page: _page,
        limit: 20,
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );
      final List<dynamic> rawReviews = result['data'] is List ? result['data'] : (result['data']?['reviews'] ?? []);
      final total = (result['meta']?['total'] as num?)?.toInt() ?? rawReviews.length;
      final reviews = rawReviews.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();

      setState(() {
        if (isLoadMore) {
          _reviews.addAll(reviews);
        } else {
          _reviews = reviews;
        }
        _hasMore = _reviews.length < total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moderate(String reviewId, String status, {String reason = ''}) async {
    if (status == 'rejected' && reason.isEmpty) {
      reason = await _showRejectDialog() ?? '';
      if (reason.isEmpty) return;
    }
    try {
      await widget.adminRepository.moderateReview(reviewId, status, reason: reason);
      _reviews.removeWhere((r) => r.id == reviewId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review ${status == 'approved' ? 'approved' : 'rejected'}!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Review'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.adminRepository.deleteReview(reviewId);
      _reviews.removeWhere((r) => r.id == reviewId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reject Review'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'hidden': return 'Hidden';
      default: return status;
    }
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'hidden': return AppColors.textMuted;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Moderation')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _statusFilter = val ?? '';
                      _page = 1;
                      _reviews = [];
                    });
                    _fetchReviews();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _reviews.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _reviews.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.inbox, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No reviews found', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _page = 1;
                          await _fetchReviews();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _reviews.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _reviews.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              );
                            }
                            return _buildReviewCard(_reviews[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final isPending = review.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _colorForStatus(review.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _labelForStatus(review.status),
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: _colorForStatus(review.status),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < (review.shopRating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 16,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment.isNotEmpty ? review.comment : '(No comment)',
              style: TextStyle(
                color: review.comment.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                fontStyle: review.comment.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (review.customerName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.user, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(review.customerName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
            if (review.staffId != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(LucideIcons.scissors, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Staff: ${review.staffId}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(review.createdAt, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const Divider(height: 20),
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                      onPressed: () => _moderate(review.id, 'approved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: review.comment.isNotEmpty ? () => _moderate(review.id, 'rejected') : null,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Delete Review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => _deleteReview(review.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}