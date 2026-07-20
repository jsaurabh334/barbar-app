import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/delivery_repository.dart';

class DeliveryOtpScreen extends StatefulWidget {
  final String orderId;
  final String title;
  final String subtitle;
  final String otpType;

  const DeliveryOtpScreen({
    super.key,
    required this.orderId,
    this.title = 'Enter OTP',
    this.subtitle = 'Ask the customer for the OTP',
    this.otpType = 'delivery',
  });

  @override
  State<DeliveryOtpScreen> createState() => _DeliveryOtpScreenState();
}

class _DeliveryOtpScreenState extends State<DeliveryOtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _attempts = 0;
  bool _success = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 4) {
      setState(() => _error = 'Enter a valid 4-digit OTP');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final repo = context.read<DeliveryRepository>();
      await repo.verifyOtp(widget.orderId, otp, otpType: widget.otpType);
      if (!mounted) return;
      setState(() { _success = true; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      _attempts++;
      final remaining = 5 - _attempts;
      setState(() {
        _error = remaining > 0
            ? 'Invalid OTP. $remaining attempt(s) remaining.'
            : 'Too many attempts. Please contact support.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _success ? LucideIcons.checkCircle : LucideIcons.shield,
                size: 64,
                color: _success ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _success ? 'Verified Successfully!' : widget.subtitle,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              if (!_success) ...[
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, letterSpacing: 12, color: Colors.white),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '0000',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3), fontSize: 32, letterSpacing: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
                ),
              ] else ...[
                const SizedBox(height: 24),
                const Text('You can now proceed with the delivery',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
