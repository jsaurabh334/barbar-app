import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_campaigns_bloc.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/data/models/campaign_model.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_empty_state.dart';

class AdminCampaignsScreen extends StatefulWidget {
  const AdminCampaignsScreen({super.key});
  @override
  State<AdminCampaignsScreen> createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends State<AdminCampaignsScreen> {
  final _scrollController = ScrollController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<AdminCampaignsBloc>().add(const LoadCampaigns());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<AdminCampaignsBloc>().state;
      if (state is AdminCampaignsLoaded && !state.hasReachedMax) {
        context.read<AdminCampaignsBloc>().add(LoadCampaigns(
          page: state.currentPage + 1,
          status: _statusFilter,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AdminCampaignsBloc, AdminCampaignsState>(
        listener: (context, state) {
          if (state is AdminCampaignActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ));
            context.read<AdminCampaignsBloc>().add(const LoadCampaigns());
          }
          if (state is AdminCampaignsError) {
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
        onPressed: () => _showCampaignForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', null),
            const SizedBox(width: 8),
            _buildFilterChip('Draft', 'draft'),
            const SizedBox(width: 8),
            _buildFilterChip('Scheduled', 'scheduled'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed'),
            const SizedBox(width: 8),
            _buildFilterChip('Failed', 'failed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        context.read<AdminCampaignsBloc>().add(LoadCampaigns(status: value));
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

  Widget _buildBody(AdminCampaignsState state) {
    if (state is AdminCampaignsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AdminCampaignsLoaded) {
      if (state.campaigns.isEmpty) {
        return const AdminEmptyState(
          icon: LucideIcons.megaphone,
          title: 'No Campaigns',
          subtitle: 'Tap + to create your first campaign',
        );
      }
      return RefreshIndicator(
        onRefresh: () async => context.read<AdminCampaignsBloc>().add(const LoadCampaigns()),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: state.campaigns.length + (state.hasReachedMax ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= state.campaigns.length) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ));
            }
            return _CampaignCard(
              campaign: state.campaigns[index],
              onTap: () => _showDetail(context, state.campaigns[index]),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showCampaignForm(BuildContext context, {CampaignModel? campaign}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<AdminCampaignsBloc>(),
        child: _CampaignFormScreen(campaign: campaign),
      ),
    ));
  }

  void _showDetail(BuildContext context, CampaignModel campaign) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<AdminCampaignsBloc>(),
        child: _CampaignDetailScreen(campaign: campaign),
      ),
    ));
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onTap;
  const _CampaignCard({required this.campaign, required this.onTap});

  Color _statusColor() {
    switch (campaign.status) {
      case 'draft': return Colors.grey;
      case 'scheduled': return Colors.orange;
      case 'sending': return AppColors.primary;
      case 'completed': return Colors.green;
      case 'failed': return AppColors.error;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.megaphone, color: _statusColor(), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(campaign.targetLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (campaign.isCompleted) ...[
                    const SizedBox(height: 2),
                    Text('Sent: ${campaign.sentCount}/${campaign.totalRecipients}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(campaign.statusLabel.toUpperCase(), style: TextStyle(color: _statusColor(), fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignDetailScreen extends StatelessWidget {
  final CampaignModel campaign;
  const _CampaignDetailScreen({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminCampaignsBloc>();
    return Scaffold(
      appBar: AppBar(title: Text(campaign.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (campaign.imageUrl != null && campaign.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(campaign.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (campaign.imageUrl != null && campaign.imageUrl!.isNotEmpty) const SizedBox(height: 16),
            _buildRow('Status', campaign.statusLabel),
            _buildRow('Target', campaign.targetLabel),
            _buildRow('Message', campaign.message),
            if (campaign.scheduledAt != null) _buildRow('Scheduled', campaign.scheduledAt!.substring(0, 16).replaceAll('T', ' ')),
            if (campaign.isCompleted) ...[
              const SizedBox(height: 16),
              const Text('Delivery Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildRow('Recipients', campaign.totalRecipients.toString()),
              _buildRow('Sent', campaign.sentCount.toString()),
              _buildRow('Failed', campaign.failedCount.toString()),
            ],
            const SizedBox(height: 24),
            if (!campaign.isCompleted)
              ElevatedButton.icon(
                onPressed: () {
                  bloc.add(SendCampaign(campaign.id));
                  Navigator.of(context).pop();
                },
                icon: const Icon(LucideIcons.send),
                label: const Text('Send Campaign Now'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            if (!campaign.isCompleted) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  bloc.add(DeleteCampaign(campaign.id));
                  Navigator.of(context).pop();
                },
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text('Delete Campaign'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _CampaignFormScreen extends StatefulWidget {
  final CampaignModel? campaign;
  const _CampaignFormScreen({this.campaign});
  @override
  State<_CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<_CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late final TextEditingController _imageUrlController;
  String _targetType = 'all';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.campaign?.title ?? '');
    _messageController = TextEditingController(text: widget.campaign?.message ?? '');
    _imageUrlController = TextEditingController(text: widget.campaign?.imageUrl ?? '');
    _targetType = widget.campaign?.targetType ?? 'all';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.campaign != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Campaign' : 'New Campaign'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold))),
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
                decoration: const InputDecoration(labelText: 'Campaign Title', hintText: 'e.g. Weekend Sale'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message', hintText: 'Push notification body text'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)', hintText: 'https://...'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _targetType,
                decoration: const InputDecoration(labelText: 'Target Audience'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(value: 'customers', child: Text('Customers')),
                  DropdownMenuItem(value: 'barbers', child: Text('Barbers')),
                  DropdownMenuItem(value: 'vendors', child: Text('Vendors')),
                  DropdownMenuItem(value: 'delivery', child: Text('Delivery Partners')),
                ],
                onChanged: (v) => setState(() => _targetType = v!),
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
      'message': _messageController.text.trim(),
      'target_type': _targetType,
    };
    if (_imageUrlController.text.trim().isNotEmpty) data['image_url'] = _imageUrlController.text.trim();
    if (widget.campaign != null) {
      context.read<AdminCampaignsBloc>().add(UpdateCampaign(widget.campaign!.id, data));
    } else {
      context.read<AdminCampaignsBloc>().add(CreateCampaign(data));
    }
    Navigator.of(context).pop();
  }
}
