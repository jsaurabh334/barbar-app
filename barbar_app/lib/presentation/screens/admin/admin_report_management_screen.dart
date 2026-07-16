import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

class AdminReportManagementScreen extends StatefulWidget {
  final AdminRepository adminRepository;

  const AdminReportManagementScreen({super.key, required this.adminRepository});

  @override
  State<AdminReportManagementScreen> createState() => _AdminReportManagementScreenState();
}

class _AdminReportManagementScreenState extends State<AdminReportManagementScreen> {
  String _statusFilter = '';
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchReports();
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
      _fetchReports(isLoadMore: true);
    }
  }

  Future<void> _fetchReports({bool isLoadMore = false}) async {
    if (!isLoadMore) setState(() => _isLoading = true);
    try {
      final result = await widget.adminRepository.getAllReports(
        page: _page,
        limit: 20,
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );
      final List<dynamic> rawReports = result['data'] is List ? result['data'] : [];
      final total = (result['meta']?['total'] as num?)?.toInt() ?? rawReports.length;
      final reports = rawReports.map((e) => e as Map<String, dynamic>).toList();
      if (!mounted) return;
      setState(() {
        if (isLoadMore) { _reports.addAll(reports); } else { _reports = reports; }
        _hasMore = _reports.length < total;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveReport(String reportId, String status) async {
    try {
      await widget.adminRepository.resolveReport(reportId, status);
      _reports.removeWhere((r) => r['id'] == reportId);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report ${status == 'resolved' ? 'resolved' : 'dismissed'}'),
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

  String _reasonLabel(String reason) {
    const labels = {'spam': 'Spam', 'fake': 'Fake', 'abusive': 'Abusive', 'wrong_information': 'Wrong Info', 'other': 'Other'};
    return labels[reason] ?? reason;
  }

  IconData _reasonIcon(String reason) {
    switch (reason) {
      case 'spam': return LucideIcons.mailWarning;
      case 'fake': return LucideIcons.alertTriangle;
      case 'abusive': return LucideIcons.alertOctagon;
      case 'wrong_information': return LucideIcons.info;
      default: return LucideIcons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Queue')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _statusFilter,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
                  ],
                  onChanged: (val) {
                    setState(() { _statusFilter = val ?? ''; _page = 1; _reports = []; });
                    _fetchReports();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _reports.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _reports.isEmpty
                    ? const Center(child: Text('No reports', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: () async { _page = 1; await _fetchReports(); },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _reports.length) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)));
                            }
                            return _buildReportCard(_reports[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final reason = report['reason'] as String? ?? '';
    final customReason = report['custom_reason'] as String?;
    final status = report['status'] as String? ?? 'pending';
    final review = report['review'] as Map<String, dynamic>?;
    final reporter = report['reporter'] as Map<String, dynamic>?;
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? AppColors.error.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_reasonIcon(reason), size: 18, color: isPending ? AppColors.error : AppColors.textMuted),
                const SizedBox(width: 8),
                Text(_reasonLabel(reason), style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14,
                  color: isPending ? AppColors.error : AppColors.textPrimary,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.warning.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isPending ? AppColors.warning : AppColors.success,
                  )),
                ),
              ],
            ),
            if (customReason != null && customReason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(customReason, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (reporter != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Reported by: ${reporter['full_name'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
            if (review != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.messageSquare, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      (review['comment'] as String? ?? '').isNotEmpty
                          ? review['comment'] as String
                          : '(No comment)',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Resolve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success),
                      ),
                      onPressed: () => _resolveReport(report['id'] as String, 'resolved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted, side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () => _resolveReport(report['id'] as String, 'dismissed'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
