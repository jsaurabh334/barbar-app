import 'package:flutter/material.dart';
import 'package:barbar_app/core/theme/app_theme.dart';

class AdminAnalyticsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final String? subtitle;
  final List<Widget>? actions;

  const AdminAnalyticsSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                ],
              ),
              if (actions != null) Row(children: actions!),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ],
    );
  }
}
