import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class DeliverySupportScreen extends StatelessWidget {
  const DeliverySupportScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Delivery%20Partner%20Support');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Hotline', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), AppColors.cardBg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.shieldAlert, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency SOS Assistance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Immediate dispatch help for road safety & accidents.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _makeCall('112'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('SOS 112', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('CONTACT SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildContactCard(
              title: '24/7 Delivery Partner Desk',
              subtitle: '+91 1800-572-9000',
              icon: LucideIcons.phoneCall,
              color: Colors.greenAccent,
              onTap: () => _makeCall('+9118005729000'),
            ),
            _buildContactCard(
              title: 'WhatsApp Partner Dispatch',
              subtitle: '+91 98765 43210',
              icon: LucideIcons.messageSquare,
              color: AppColors.primary,
              onTap: () => _makeCall('+919876543210'),
            ),
            _buildContactCard(
              title: 'Email Operations Team',
              subtitle: 'delivery-support@barbar.in',
              icon: LucideIcons.mail,
              color: Colors.cyanAccent,
              onTap: () => _sendEmail('delivery-support@barbar.in'),
            ),
            const SizedBox(height: 24),
            const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildFaqExpansion('How do I receive my trip earnings payouts?', 'Earnings are automatically settled directly to your linked bank account every Tuesday morning. You can also request instant withdrawal from the Wallet screen.'),
            _buildFaqExpansion('What if the vendor/customer OTP fails?', 'You can tap "Regenerate OTP" on the OTP screen to resend a new OTP to the customer or vendor via SMS.'),
            _buildFaqExpansion('What should I do if customer location is wrong?', 'Tap the "Open in Google Maps" button to view full turn-by-turn navigation or contact customer directly using the Call button.'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqExpansion(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          )
        ],
      ),
    );
  }
}
