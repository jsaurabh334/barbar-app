import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminCrudBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final String buttonLabel;
  final VoidCallback onSave;
  final bool isLoading;

  const AdminCrudBottomSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.buttonLabel,
    required this.onSave,
    this.isLoading = false,
  });

  static Future<void> show(BuildContext context, {
    required String title,
    required List<Widget> fields,
    required String buttonLabel,
    required VoidCallback onSave,
    bool isLoading = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: AdminCrudBottomSheet(
          title: title,
          fields: fields,
          buttonLabel: buttonLabel,
          onSave: onSave,
          isLoading: isLoading,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...fields,
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
