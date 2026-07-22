import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_banners_bloc.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/data/models/banner_model.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_delete_dialog.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_empty_state.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_status_badge.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});
  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _scrollController = ScrollController();
  String? _positionFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<AdminBannersBloc>().add(const LoadBanners());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<AdminBannersBloc>().state;
      if (state is AdminBannersLoaded && !state.hasReachedMax) {
        context.read<AdminBannersBloc>().add(LoadBanners(
          page: state.currentPage + 1,
          position: _positionFilter,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AdminBannersBloc, AdminBannersState>(
        listener: (context, state) {
          if (state is AdminBannerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ));
            context.read<AdminBannersBloc>().add(const LoadBanners());
          }
          if (state is AdminBannersError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildFilterBar(),
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBannerForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBg,
      child: Row(
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('Home Top', 'home_top'),
          const SizedBox(width: 8),
          _buildFilterChip('Home Middle', 'home_middle'),
          const SizedBox(width: 8),
          _buildFilterChip('Promotions', 'promotions'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _positionFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _positionFilter = value);
        context.read<AdminBannersBloc>().add(LoadBanners(position: value));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12, fontWeight: FontWeight.w500,
        )),
      ),
    );
  }

  Widget _buildBody(AdminBannersState state) {
    if (state is AdminBannersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AdminBannersLoaded) {
      if (state.banners.isEmpty) {
        return const AdminEmptyState(
          icon: LucideIcons.image,
          title: 'No Banners',
          subtitle: 'Tap + to create your first banner',
        );
      }
      return RefreshIndicator(
        onRefresh: () async => context.read<AdminBannersBloc>().add(const LoadBanners()),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: state.banners.length + (state.hasReachedMax ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= state.banners.length) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ));
            }
            return _BannerCard(
              banner: state.banners[index],
              onEdit: () => _showBannerForm(context, banner: state.banners[index]),
              onDelete: () => _confirmDelete(context, state.banners[index]),
              onToggle: () => context.read<AdminBannersBloc>().add(ToggleBannerActive(state.banners[index].id)),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showBannerForm(BuildContext context, {BannerModel? banner}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBannersBloc>(),
        child: _BannerFormScreen(banner: banner),
      ),
    ));
  }

  void _confirmDelete(BuildContext context, BannerModel banner) {
    AdminDeleteDialog.show(
      context,
      title: 'Delete Banner',
      itemName: banner.title,
      onConfirm: () => context.read<AdminBannersBloc>().add(DeleteBanner(banner.id)),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _BannerCard({required this.banner, required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              banner.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140, color: Colors.grey[850],
                child: const Center(child: Icon(LucideIcons.imageOff, color: Colors.grey)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(banner.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    AdminStatusBadge(label: banner.isActive ? 'Active' : 'Inactive'),
                    if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.externalLink, size: 14, color: AppColors.textSecondary),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _PositionBadge(banner.position),
                    const SizedBox(width: 8),
                    Text('Order: ${banner.sortOrder}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (banner.startDate != null) ...[
                      const SizedBox(width: 8),
                      Text('From: ${banner.startDate!.substring(0, 10)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(LucideIcons.toggleLeft, size: 18), onPressed: onToggle, tooltip: 'Toggle Active'),
                    IconButton(icon: const Icon(LucideIcons.pencil, size: 18), onPressed: onEdit, tooltip: 'Edit'),
                    IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error), onPressed: onDelete, tooltip: 'Delete'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final String position;
  const _PositionBadge(this.position);
  @override
  Widget build(BuildContext context) {
    final label = position.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _BannerFormScreen extends StatefulWidget {
  final BannerModel? banner;
  const _BannerFormScreen({this.banner});
  @override
  State<_BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<_BannerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _linkUrlController;
  late final TextEditingController _sortOrderController;
  String _position = 'home_top';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _imageUrlController = TextEditingController(text: widget.banner?.imageUrl ?? '');
    _linkUrlController = TextEditingController(text: widget.banner?.linkUrl ?? '');
    _sortOrderController = TextEditingController(text: (widget.banner?.sortOrder ?? 0).toString());
    _position = widget.banner?.position ?? 'home_top';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _linkUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.banner != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Banner' : 'Create Banner'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'Enter banner title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Image URL is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkUrlController,
                decoration: const InputDecoration(labelText: 'Link URL (optional)', hintText: 'https://...'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _position,
                decoration: const InputDecoration(labelText: 'Position'),
                items: const [
                  DropdownMenuItem(value: 'home_top', child: Text('Home Top')),
                  DropdownMenuItem(value: 'home_middle', child: Text('Home Middle')),
                  DropdownMenuItem(value: 'promotions', child: Text('Promotions')),
                ],
                onChanged: (v) => setState(() => _position = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(labelText: 'Sort Order', hintText: '0'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'image_url': _imageUrlController.text.trim(),
      'position': _position,
      'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
    };
    if (_linkUrlController.text.trim().isNotEmpty) data['link_url'] = _linkUrlController.text.trim();
    if (widget.banner != null) {
      context.read<AdminBannersBloc>().add(UpdateBanner(widget.banner!.id, data));
    } else {
      context.read<AdminBannersBloc>().add(CreateBanner(data));
    }
    Navigator.of(context).pop();
  }
}
