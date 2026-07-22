import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminDeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final String itemName;
  final VoidCallback onConfirm;

  const AdminDeleteDialog({
    super.key,
    this.title = 'Delete',
    this.message = 'Are you sure you want to delete this',
    required this.itemName,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, {required String itemName, VoidCallback? onConfirm, String title = 'Delete'}) {
    return showDialog(
      context: context,
      builder: (ctx) => AdminDeleteDialog(
        title: title,
        itemName: itemName,
        onConfirm: onConfirm ?? () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      title: Text(title),
      content: Text('$message $itemName?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
