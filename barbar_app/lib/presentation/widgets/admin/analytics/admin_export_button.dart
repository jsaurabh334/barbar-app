import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminExportButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isExporting;

  const AdminExportButton({
    super.key,
    this.onPressed,
    this.isExporting = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isExporting
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(LucideIcons.download, size: 20),
      onPressed: isExporting ? null : onPressed,
      tooltip: 'Export CSV',
      color: AppColors.primary,
    );
  }
}
