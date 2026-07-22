import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_empty_state.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_search_toolbar.dart';

class AdminCrudListPage extends StatelessWidget {
  final String title;
  final String createButtonLabel;
  final List<Widget> items;
  final bool isLoading;
  final bool isEmpty;
  final bool hasMore;
  final VoidCallback? onCreate;
  final VoidCallback? onLoadMore;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final IconData? emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final Widget? filterBar;
  final Widget? header;

  const AdminCrudListPage({
    super.key,
    required this.title,
    this.createButtonLabel = 'Create',
    required this.items,
    this.isLoading = false,
    this.isEmpty = false,
    this.hasMore = false,
    this.onCreate,
    this.onLoadMore,
    this.searchController,
    this.onSearchChanged,
    this.searchHint,
    this.emptyIcon,
    this.emptyTitle,
    this.emptySubtitle,
    this.filterBar,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        if (searchController != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: AdminSearchToolbar(
              controller: searchController!,
              onChanged: onSearchChanged ?? (_) {},
              hintText: searchHint ?? 'Search $title...',
            ),
          ),
        if (filterBar != null) ...[
          const SizedBox(height: 8),
          filterBar!,
        ],
        if (onCreate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(createButtonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        Expanded(
          child: isLoading && items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : isEmpty
                  ? AdminEmptyState(
                      icon: emptyIcon ?? LucideIcons.inbox,
                      title: emptyTitle ?? 'No $title found',
                      subtitle: emptySubtitle,
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (!hasMore || onLoadMore == null) return false;
                        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                          onLoadMore!();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          return items[index];
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
