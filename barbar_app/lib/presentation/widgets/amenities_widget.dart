import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AmenitiesWidget extends StatelessWidget {
  final List<String> amenities;

  static const _amenityMeta = {
    'wifi':        {'icon': Icons.wifi,           'label': 'WiFi'},
    'parking':     {'icon': Icons.local_parking,  'label': 'Parking'},
    'ac':          {'icon': Icons.ac_unit,        'label': 'AC'},
    'coffee':      {'icon': Icons.free_breakfast, 'label': 'Coffee'},
    'card_payment':{'icon': Icons.credit_card,    'label': 'Card Accepted'},
  };

  const AmenitiesWidget({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amenities', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: amenities.map((a) => _buildChip(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String key) {
    final meta = _amenityMeta[key];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta?['icon'] as IconData? ?? Icons.check_circle,
               size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            meta?['label'] as String? ?? key,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
