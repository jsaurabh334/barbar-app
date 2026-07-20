import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/data/models/review_model.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/barber_model.dart';
import '../../domain/repositories/review_repository.dart';
import '../widgets/glass_card.dart';
import '../widgets/review_card.dart';

class StaffDetailScreen extends StatefulWidget {
  final StaffModel staff;
  final BarberModel barber;

  const StaffDetailScreen({
    super.key,
    required this.staff,
    required this.barber,
  });

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  Map<String, dynamic>? _ratingSummary;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final repo = context.read<ReviewRepository>();
      final profile = await repo.getStaffProfile(widget.staff.id);
      final reviewsResult = await repo.getStaffReviews(widget.staff.id, page: 1, limit: 5);

      final ratingSummary = profile['rating_summary'] as Map<String, dynamic>?;
      final rawReviews = reviewsResult['data'] is Map
          ? (reviewsResult['data'] as Map)['reviews'] as List?
          : reviewsResult['reviews'] as List?;

      if (!mounted) return;
      setState(() {
        _ratingSummary = ratingSummary;
        _reviews = (rawReviews ?? [])
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapDaysToText(String? days) {
    if (days == null || days.isEmpty) return '';
    final map = {'0': 'Sun', '1': 'Mon', '2': 'Tue', '3': 'Wed', '4': 'Thu', '5': 'Fri', '6': 'Sat'};
    return days.split(',').map((e) => map[e.trim()] ?? e.trim()).join(', ');
  }

  String _ratingLabel(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Good';
    if (rating >= 3.0) return 'Average';
    if (rating >= 2.0) return 'Poor';
    return 'Very Bad';
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = (_ratingSummary?['avg_rating'] as num?)?.toDouble() ?? widget.staff.rating;
    final reviewCount = (_ratingSummary?['total_reviews'] as num?)?.toInt() ?? widget.staff.reviewCount;
    final dist = _ratingSummary?['distribution'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.staff.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Photo & Name
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: widget.staff.image != null && widget.staff.image!.isNotEmpty
                        ? NetworkImage(widget.staff.image!)
                        : null,
                    child: widget.staff.image == null || widget.staff.image!.isEmpty
                        ? const Icon(LucideIcons.user, size: 40, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(widget.staff.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.staff.roleLabel,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  // Rating Section
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.star, size: 22, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Text(avgRating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('($reviewCount reviews)',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_ratingLabel(avgRating),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),

                        // Rating Distribution
                        _distBar(5, dist['5'] as int? ?? 0, reviewCount),
                        const SizedBox(height: 6),
                        _distBar(4, dist['4'] as int? ?? 0, reviewCount),
                        const SizedBox(height: 6),
                        _distBar(3, dist['3'] as int? ?? 0, reviewCount),
                        const SizedBox(height: 6),
                        _distBar(2, dist['2'] as int? ?? 0, reviewCount),
                        const SizedBox(height: 6),
                        _distBar(1, dist['1'] as int? ?? 0, reviewCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailSection(LucideIcons.briefcase, 'Experience',
                            '${widget.staff.experienceYears} years'),
                        if (widget.staff.languages.isNotEmpty) ...[
                          const Divider(height: 24, color: AppColors.border),
                          _detailSection(
                              LucideIcons.globe, 'Languages', widget.staff.languages.join(', ')),
                        ],
                        if (widget.staff.bio != null && widget.staff.bio!.isNotEmpty) ...[
                          const Divider(height: 24, color: AppColors.border),
                          _detailSection(LucideIcons.info, 'About', widget.staff.bio!),
                        ],
                        if (widget.staff.specializations != null &&
                            widget.staff.specializations!.isNotEmpty) ...[
                          const Divider(height: 24, color: AppColors.border),
                          _detailSection(LucideIcons.scissors, 'Specializations',
                              widget.staff.specializations!),
                        ],
                        const Divider(height: 24, color: AppColors.border),
                        _detailSection(LucideIcons.clock, 'Working Hours',
                            '${widget.staff.startTime ?? 'N/A'} - ${widget.staff.endTime ?? 'N/A'}'),
                        if (widget.staff.workingDays != null &&
                            widget.staff.workingDays!.isNotEmpty) ...[
                          const Divider(height: 24, color: AppColors.border),
                          _detailSection(LucideIcons.calendar, 'Working Days',
                              _mapDaysToText(widget.staff.workingDays)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Services
                  if (widget.staff.services != null && widget.staff.services!.isNotEmpty) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Services',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...widget.staff.services!.map((s) {
                            final svc = s['service'] as Map<String, dynamic>?;
                            final svcName =
                                svc?['name'] as String? ?? s['service_id'] as String? ?? 'Service';
                            final price = (s['price'] as num?)?.toDouble() ?? 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.scissors,
                                      size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(svcName,
                                          style: const TextStyle(fontSize: 13))),
                                  if (price > 0)
                                    Text('₹${price.toInt()}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Latest Reviews
                  if (_reviews.isNotEmpty) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Latest Reviews',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ..._reviews.take(3).map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ReviewCard(review: r),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, widget.staff.id),
                      icon: const Icon(LucideIcons.calendarCheck),
                      label: Text('Book with ${widget.staff.name}'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _distBar(int star, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text('$star★', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _detailSection(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
