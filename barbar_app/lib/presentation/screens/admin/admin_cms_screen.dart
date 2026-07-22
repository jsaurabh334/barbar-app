import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_cms_bloc.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/data/models/cms_page_model.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_delete_dialog.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_empty_state.dart';

class AdminCmsScreen extends StatefulWidget {
  const AdminCmsScreen({super.key});
  @override
  State<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends State<AdminCmsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocListener<AdminCmsBloc, AdminCmsState>(
          listener: (context, state) {
            if (state is AdminCmsActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ));
              final type = _tabController.index == 0 ? 'page' : 'faq';
              context.read<AdminCmsBloc>().add(LoadCmsPages(type: type));
            }
            if (state is AdminCmsError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ));
            }
          },
          child: Container(),
        ),
        Container(
          color: AppColors.cardBg,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            onTap: (i) {
              context.read<AdminCmsBloc>().add(LoadCmsPages(type: i == 0 ? 'page' : 'faq'));
            },
            tabs: const [
              Tab(text: 'Pages'),
              Tab(text: 'FAQ'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CmsListTab(type: 'page'),
              _CmsListTab(type: 'faq'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CmsListTab extends StatefulWidget {
  final String type;
  const _CmsListTab({required this.type});
  @override
  State<_CmsListTab> createState() => _CmsListTabState();
}

class _CmsListTabState extends State<_CmsListTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCmsBloc>().add(LoadCmsPages(type: widget.type));
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageType = widget.type;
    return Scaffold(
      body: BlocBuilder<AdminCmsBloc, AdminCmsState>(
        builder: (context, state) {
          if (state is AdminCmsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminCmsLoaded) {
            final pages = state.pages.where((p) => p.type == pageType).toList();
            if (pages.isEmpty) {
              return AdminEmptyState(
                icon: LucideIcons.fileText,
                title: pageType == 'page' ? 'No Pages' : 'No FAQ Items',
                subtitle: 'Tap + to add',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<AdminCmsBloc>().add(LoadCmsPages(type: pageType)),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pages.length,
                itemBuilder: (context, index) => _CmsPageCard(
                  page: pages[index],
                  onEdit: () => _showForm(context, page: pages[index]),
                  onDelete: () => _confirmDelete(context, pages[index]),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showForm(BuildContext context, {CmsPageModel? page}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<AdminCmsBloc>(),
        child: _CmsFormScreen(page: page, pageType: widget.type),
      ),
    ));
  }

  void _confirmDelete(BuildContext context, CmsPageModel page) {
    AdminDeleteDialog.show(
      context,
      title: 'Delete ${page.typeLabel}',
      itemName: page.title,
      onConfirm: () => context.read<AdminCmsBloc>().add(DeleteCmsPage(page.id)),
    );
  }
}

class _CmsPageCard extends StatelessWidget {
  final CmsPageModel page;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CmsPageCard({required this.page, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Icon(page.type == 'faq' ? LucideIcons.helpCircle : LucideIcons.fileText, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(page.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (page.isPublished ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  page.isPublished ? 'PUBLISHED' : 'DRAFT',
                  style: TextStyle(color: page.isPublished ? Colors.green : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (page.content.length > 100) ...[
            const SizedBox(height: 8),
            Text('${page.content.substring(0, 100)}...', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(icon: const Icon(LucideIcons.pencil, size: 18), onPressed: onEdit, tooltip: 'Edit'),
              IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error), onPressed: onDelete, tooltip: 'Delete'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CmsFormScreen extends StatefulWidget {
  final CmsPageModel? page;
  final String pageType;
  const _CmsFormScreen({this.page, required this.pageType});
  @override
  State<_CmsFormScreen> createState() => _CmsFormScreenState();
}

class _CmsFormScreenState extends State<_CmsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyController;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _sortOrderController;
  bool _isPublished = true;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.page?.key ?? '');
    _titleController = TextEditingController(text: widget.page?.title ?? '');
    _contentController = TextEditingController(text: widget.page?.content ?? '');
    _sortOrderController = TextEditingController(text: (widget.page?.sortOrder ?? 0).toString());
    _isPublished = widget.page?.isPublished ?? true;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.page != null;
    final isFaq = widget.pageType == 'faq';
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit ${isFaq ? "FAQ" : "Page"}' : 'New ${isFaq ? "FAQ" : "Page"}'),
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
                controller: _keyController,
                decoration: const InputDecoration(labelText: 'Key/Slug', hintText: 'e.g. privacy-policy, faq-1'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Key is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: isFaq ? 'Question' : 'Title', hintText: isFaq ? 'e.g. How do I book?' : 'e.g. Privacy Policy'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: isFaq ? 'Answer' : 'Content'),
                maxLines: 8,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(labelText: 'Sort Order', hintText: '0'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Published'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
                contentPadding: EdgeInsets.zero,
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
      'key': _keyController.text.trim(),
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'type': widget.pageType,
      'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
      'is_published': _isPublished,
    };
    if (widget.page != null) {
      context.read<AdminCmsBloc>().add(UpdateCmsPage(widget.page!.id, data));
    } else {
      context.read<AdminCmsBloc>().add(CreateCmsPage(data));
    }
    Navigator.of(context).pop();
  }
}
