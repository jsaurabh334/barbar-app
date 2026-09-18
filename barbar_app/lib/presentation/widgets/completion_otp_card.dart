import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/booking_model.dart';
import '../bloc/booking/booking_bloc.dart';
import '../bloc/booking/booking_event.dart';

/// Shows the completion OTP to the customer on home service bookings that are
/// awaiting customer confirmation, with Resend OTP and Problem Still Exists
/// actions. Shared between the customer home screen and booking history.
class CompletionOtpCard extends StatelessWidget {
  final BookingModel booking;
  final String? otp;

  const CompletionOtpCard({super.key, required this.booking, this.otp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Service Completed?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Share this OTP with the barber only if you are satisfied with the service.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (otp != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  otp!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.share2, size: 16),
                label: const Text('Share OTP'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(color: AppColors.warning.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _shareOtp(context, otp!),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.clock, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OTP is on its way. If it doesn\'t arrive, tap Resend OTP.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniButton('RESEND OTP', AppColors.info, () => _resendOtp(context)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniButton('PROBLEM STILL EXISTS', AppColors.error, () => _reportProblem(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resendOtp(BuildContext context) {
    context.read<BookingBloc>().add(ResendCompletionOtp(booking.id));
  }

  Future<void> _shareOtp(BuildContext context, String otp) async {
    await Clipboard.setData(ClipboardData(text: otp));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP copied to clipboard'), backgroundColor: AppColors.success),
    );
  }

  void _reportProblem(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Report Problem?'),
        content: const Text(
          'The service is not finished yet. This will notify the barber to resume the service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BookingBloc>().add(ProblemStillExists(booking.id));
            },
            child: const Text('REPORT', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _miniButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
