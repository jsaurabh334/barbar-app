import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/vendor_model.dart';
import '../../../domain/repositories/directory_repository.dart';

class VendorDetailScreen extends StatefulWidget {
  final String vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  VendorModel? _vendor;
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
        setState(() { _vendor = vendor; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_vendor?.businessName ?? 'Seller')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _vendor == null
                  ? const Center(child: Text('Seller not found'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final v = _vendor!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Header
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                child: Text(v.businessName.isNotEmpty ? v.businessName[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 28, color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.businessName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (v.businessDescription != null && v.businessDescription!.isNotEmpty)
                      Text(v.businessDescription!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contact Info
          if (v.businessEmail != null || v.businessPhone != null) ...[
            _buildInfoTile(LucideIcons.mail, v.businessEmail ?? ''),
            _buildInfoTile(LucideIcons.phone, v.businessPhone ?? ''),
          ],

          // Address
          if (v.address != null) ...[
            const SizedBox(height: 12),
            _buildInfoTile(LucideIcons.mapPin, '${v.address}, ${v.city ?? ""}${v.state != null ? ", ${v.state}" : ""}'),
          ],

          // Warehouses
          if (v.warehouses != null && v.warehouses!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Pickup Locations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...v.warehouses!.map((w) => Card(
                  color: AppColors.cardBg,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(LucideIcons.warehouse, color: AppColors.primary),
                    title: Text(w.name),
                    subtitle: Text('${w.address}, ${w.city}'),
                    trailing: Text(w.warehouseType, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ),
                )),
          ],

          // GST
          if (v.gstNumber != null && v.gstNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoTile(LucideIcons.fileText, 'GST: ${v.gstNumber}'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
        ],
      ),
    );
  }
}
