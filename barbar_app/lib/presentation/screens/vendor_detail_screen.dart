import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/vendor_model.dart';
import '../../data/models/vendor_branch_model.dart';
import '../../data/models/vendor_image_model.dart';
import '../../domain/repositories/directory_repository.dart';

class VendorDetailScreen extends StatefulWidget {
  final String vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  VendorModel? _vendor;
  VendorBranchModel? _selectedBranch;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  Future<void> _loadVendor() async {
    try {
      final vendor = await context.read<DirectoryRepository>().getVendorDetail(widget.vendorId);
      if (mounted) {
        setState(() {
          _vendor = vendor;
          _selectedBranch = vendor.branches?.isNotEmpty == true ? vendor.branches!.first : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  List<VendorImageModel> get _allImages {
    if (_vendor?.images == null) return [];
    final images = <VendorImageModel>[];
    for (final img in _vendor!.images!) {
      if (img.imageType == 'logo' || img.imageType == 'banner') continue;
      images.add(img);
    }
    if (_vendor!.storeLogo != null) {
      images.insert(0, VendorImageModel(id: '', vendorId: _vendor!.id, imageUrl: _vendor!.storeLogo!, imageType: 'logo', isPrimary: true));
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.store, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () { setState(() { _loading = true; _error = null; }); _loadVendor(); }, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final vendor = _vendor!;
    final images = _allImages;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: images.isNotEmpty
                ? CachedNetworkImage(imageUrl: images.first.imageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _buildPlaceholderBanner())
                : _buildPlaceholderBanner(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShopHeader(vendor),
                const SizedBox(height: 20),
                if (vendor.storeDescription != null && vendor.storeDescription!.isNotEmpty) ...[
                  Text(vendor.storeDescription!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 20),
                ],
                if (vendor.branches != null && vendor.branches!.length > 1) _buildBranchSelector(),
                if (_selectedBranch != null) ...[
                  const SizedBox(height: 20),
                  _buildBranchInfo(_selectedBranch!),
                  const SizedBox(height: 24),
                  _buildWorkingHoursCard(_selectedBranch!),
                  const SizedBox(height: 24),
                  if (_selectedBranch!.holidays != null && _selectedBranch!.holidays!.isNotEmpty)
                    _buildHolidaysCard(_selectedBranch!),
                ],
                if (images.length > 1) ...[
                  const SizedBox(height: 24),
                  _buildGallery(images),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(color: AppColors.cardBg, child: const Center(child: Icon(LucideIcons.store, size: 80, color: AppColors.textMuted)));
  }

  Widget _buildShopHeader(VendorModel vendor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vendor.storeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${vendor.city ?? ''}${vendor.city != null && vendor.state != null ? ', ' : ''}${vendor.state ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              if (vendor.storePhone != null) ...[
                const SizedBox(height: 4),
                Row(children: [const Icon(LucideIcons.phone, size: 14, color: AppColors.textSecondary), const SizedBox(width: 6), Text(vendor.storePhone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))]),
              ],
              if (vendor.storeEmail != null) ...[
                const SizedBox(height: 2),
                Row(children: [const Icon(LucideIcons.mail, size: 14, color: AppColors.textSecondary), const SizedBox(width: 6), Text(vendor.storeEmail!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))]),
              ],
            ],
          ),
        ),
        if (vendor.rating > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.star, color: AppColors.primary, size: 18), const SizedBox(width: 4), Text(vendor.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))]),
          ),
      ],
    );
  }

  Widget _buildBranchSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Branch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBranch?.id,
          decoration: InputDecoration(filled: true, fillColor: AppColors.cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: _vendor!.branches!.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
          onChanged: (v) { setState(() { _selectedBranch = _vendor!.branches!.firstWhere((b) => b.id == v); }); },
        ),
      ],
    );
  }

  Widget _buildBranchInfo(VendorBranchModel branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text(branch.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          if (branch.address.isNotEmpty) Text(branch.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (branch.phone != null) ...[const SizedBox(height: 4), Row(children: [const Icon(LucideIcons.phone, size: 13, color: AppColors.textSecondary), const SizedBox(width: 6), Text(branch.phone!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))])],
        ],
      ),
    );
  }

  Widget _buildWorkingHoursCard(VendorBranchModel branch) {
    final hours = branch.workingHours ?? [];
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = DateTime.now().weekday - 1; // 0=Mon..6=Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(LucideIcons.clock, size: 18, color: AppColors.primary), const SizedBox(width: 8), const Text('Working Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          if (hours.isEmpty)
            const Text('No hours set', style: TextStyle(color: AppColors.textSecondary))
          else
            ...List.generate(7, (i) {
              final hour = hours.where((h) => h.dayOfWeek == i).firstOrNull;
              final isToday = i == today;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(border: isToday ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null, borderRadius: isToday ? BorderRadius.circular(8) : null, color: isToday ? AppColors.primary.withValues(alpha: 0.05) : null),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(dayNames[i], style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? AppColors.primary : AppColors.textPrimary, fontSize: 13))),
                    Expanded(
                      child: hour == null || hour.isClosed
                          ? const Text('Closed', style: TextStyle(color: AppColors.error, fontSize: 13))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${hour.openTime} - ${hour.closeTime}', style: const TextStyle(fontSize: 13)),
                                if (hour.breakStart != null && hour.breakEnd != null)
                                  Text('Break: ${hour.breakStart} - ${hour.breakEnd}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHolidaysCard(VendorBranchModel branch) {
    final holidays = branch.holidays!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(LucideIcons.calendarX, size: 18, color: AppColors.warning), const SizedBox(width: 8), const Text('Upcoming Holidays', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          ...holidays.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(child: Text(h.title, style: const TextStyle(fontSize: 13))),
                Text(_formatDate(h.date), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGallery(List<VendorImageModel> images) {
    final galleryImages = images.length > 1 ? images.sublist(1) : <VendorImageModel>[];
    if (galleryImages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Icon(LucideIcons.image, size: 18, color: AppColors.primary), const SizedBox(width: 8), const Text('Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: galleryImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: galleryImages[i].imageUrl, width: 120, height: 120, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.cardBg, child: const Icon(LucideIcons.image, color: AppColors.textMuted))),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return date;
    }
  }
}
