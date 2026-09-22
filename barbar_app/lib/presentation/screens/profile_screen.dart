import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/glass_card.dart';
import 'wallet_screen.dart';
import 'address_screen.dart';
import '../../domain/repositories/admin_repository.dart';
import '../bloc/admin/admin_reports_bloc.dart';
import 'admin/admin_reports_dashboard.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _ProfileBody(user: state.user);
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  final UserModel user;
  const _ProfileBody({required this.user});

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _completionAnim;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    final pct = _completionPercent(widget.user);
    _completionAnim = Tween<double>(begin: 0, end: pct / 100).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _ProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      final pct = _completionPercent(widget.user);
      _completionAnim = Tween<double>(begin: _completionAnim.value, end: pct / 100).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int _completionPercent(UserModel u) {
    int s = 0;
    if (u.fullName.isNotEmpty) s += 25;
    if (u.phone.isNotEmpty) s += 25;
    if (u.email != null && u.email!.isNotEmpty) s += 25;
    if (u.avatar != null && u.avatar!.isNotEmpty) s += 25;
    return s;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await context.read<AuthRepository>().uploadImage(image.path);
      if (mounted) {
        context.read<AuthBloc>().add(UpdateProfileRequested({'avatar': url}));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload avatar'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You\'ll need to sign in again.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.helpCircle, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Need assistance with your account, bookings, or store?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.mail, color: AppColors.primary),
              title: Text('Email Support', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text('support@barbar.app', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.phoneCall, color: AppColors.primary),
              title: Text('Helpline', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text('+91 99999 99999 (9 AM - 8 PM)', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.shield, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'BARBAR App Privacy Policy\n\n'
                  '1. Information Collection: We collect phone number, name, location data, and booking history to provide salon and grooming services.\n\n'
                  '2. Data Protection: Your personal data is encrypted in transit and at rest. We do not sell your personal information to third parties.\n\n'
                  '3. Location Usage: Real-time location data is used only to show nearby salons and track active delivery partners.\n\n'
                  '4. Your Rights: You can request profile data deletion or export by contacting support@barbar.app.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('I Understand'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'BARBAR Terms & Conditions\n\n'
                  '1. Booking Policy: Service appointments can be cancelled up to 30 minutes before the scheduled time for full refund.\n\n'
                  '2. Platform Payments: All online payments are securely processed. Refunds are credited within 3-5 business days.\n\n'
                  '3. Code of Conduct: Users and partner salons must maintain respectful behavior during appointments.\n\n'
                  '4. Modifications: BARBAR reserves the right to update pricing, service fees, or terms at any time with prior notice.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Accept & Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final pct = _completionPercent(user);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBg,
      onRefresh: () async {
        context.read<AuthBloc>().add(AppStarted());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Avatar + Info
          _buildAvatarSection(user, pct),
          const SizedBox(height: 24),

          // Completion Card
          if (pct < 100) ...[
            _buildCompletionCard(user, pct),
            const SizedBox(height: 20),
          ],

          // Quick Actions
          _buildSectionTitle('QUICK ACTIONS'),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Account
          _buildSectionTitle('ACCOUNT'),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: LucideIcons.userCog,
            title: 'Edit Profile',
            subtitle: 'Name, email, avatar',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _EditProfileScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: LucideIcons.wallet,
            title: 'Wallet',
            subtitle: 'Balance & transactions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.user.role != 'admin') ...[
            _buildMenuTile(
              icon: LucideIcons.mapPin,
              title: 'My Addresses',
              subtitle: 'Saved delivery addresses',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddressScreen(onAddressSelected: (_) {})),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Support & More
          _buildSectionTitle('SUPPORT & MORE'),
          const SizedBox(height: 12),
          _buildMenuTile(
            icon: LucideIcons.helpCircle,
            title: 'Help & Support',
            subtitle: 'FAQs, contact support',
            onTap: () => _showHelpBottomSheet(context),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: LucideIcons.shield,
            title: 'Privacy Policy',
            subtitle: 'Data & privacy info',
            onTap: () => _showPrivacyBottomSheet(context),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: LucideIcons.fileText,
            title: 'Terms of Service',
            subtitle: 'App usage terms',
            onTap: () => _showTermsBottomSheet(context),
          ),
          const SizedBox(height: 24),

          // Logout
          _buildLogoutButton(),
          const SizedBox(height: 24),

          // App Version
          Center(
            child: Column(
              children: [
                Text(
                  'BARBAR APP',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UserModel user, int pct) {
    return Column(
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickAvatar,
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _completionAnim,
                  builder: (_, __) => CustomPaint(
                    size: const Size(120, 120),
                    painter: _RingPainter(
                      progress: _completionAnim.value,
                      strokeWidth: 3.5,
                      backgroundColor: AppColors.border,
                      progressColor: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.secondary.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                        : user.fullAvatarUrl != null
                            ? Image.network(
                                user.fullAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarInitial(user),
                              )
                            : _avatarInitial(user),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.camera, size: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName.isNotEmpty ? user.fullName : 'Set Your Name',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.phone, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                user.phone.startsWith('+') ? user.phone : '+${user.phone}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        if (user.email != null && user.email!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.mail, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                user.email!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.secondary.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            user.role.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarInitial(UserModel user) {
    return Center(
      child: Text(
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCompletionCard(UserModel user, int pct) {
    final items = [
      _CompletionItem('Full Name', user.fullName.isNotEmpty, LucideIcons.user),
      _CompletionItem('Phone Number', user.phone.isNotEmpty, LucideIcons.phone),
      _CompletionItem('Email Address', user.email != null && user.email!.isNotEmpty, LucideIcons.mail),
      _CompletionItem('Profile Photo', user.avatar != null && user.avatar!.isNotEmpty, LucideIcons.camera),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pct >= 75
                      ? AppColors.success.withValues(alpha: 0.15)
                      : pct >= 50
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    color: pct >= 75
                        ? AppColors.success
                        : pct >= 50
                            ? AppColors.warning
                            : AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedBuilder(
              animation: _completionAnim,
              builder: (_, __) => LinearProgressIndicator(
                value: _completionAnim.value,
                backgroundColor: AppColors.surface,
                color: pct >= 75
                    ? AppColors.success
                    : pct >= 50
                        ? AppColors.warning
                        : AppColors.error,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: item.done
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.done ? LucideIcons.check : item.icon,
                        size: 14,
                        color: item.done ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: item.done ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: item.done ? FontWeight.w500 : FontWeight.normal,
                        decoration: item.done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final isAdmin = widget.user.role == 'admin';
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: LucideIcons.wallet,
            label: 'Wallet',
            color: AppColors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (!isAdmin) ...[
          Expanded(
            child: _buildQuickActionCard(
              icon: LucideIcons.mapPin,
              label: 'Addresses',
              color: AppColors.info,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddressScreen(onAddressSelected: (_) {})),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (isAdmin) ...[
          Expanded(
            child: _buildQuickActionCard(
              icon: LucideIcons.barChart3,
              label: 'Analytics',
              color: AppColors.info,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => AdminReportsBloc(
                        adminRepository: context.read<AdminRepository>(),
                      ),
                      child: const AdminReportsDashboard(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildQuickActionCard(
            icon: LucideIcons.settings,
            label: 'Settings',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _EditProfileScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primary.withValues(alpha: 0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showLogoutDialog,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.logOut, color: AppColors.error, size: 18),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionItem {
  final String label;
  final bool done;
  final IconData icon;
  const _CompletionItem(this.label, this.done, this.icon);
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  bool _isUploading = false;
  String? _avatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _nameController = TextEditingController(text: user.fullName);
    _emailController = TextEditingController(text: user.email ?? '');
    _avatarUrl = user.avatar;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await context.read<AuthRepository>().uploadImage(image.path);
      setState(() {
        _avatarUrl = url;
        _isUploading = false;
      });
      if (mounted) {
        context.read<AuthBloc>().add(UpdateProfileRequested({'avatar': url}));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'EDIT PROFILE',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && _saving) {
            _saving = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
            );
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            _saving = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                        ),
                        child: ClipOval(
                          child: _isUploading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                              : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                  ? Image.network(
                                      UserModel(id: '', phone: '', fullName: '', role: '', status: '', otpVerified: false, languagePref: '', avatar: _avatarUrl).fullAvatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(LucideIcons.user, size: 40, color: AppColors.textSecondary),
                                    )
                                  : const Icon(LucideIcons.user, size: 40, color: AppColors.textSecondary),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                          child: const Icon(LucideIcons.camera, size: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: LucideIcons.user,
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildInfoRow(LucideIcons.phone, 'Phone Number', () {
                  final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
                  return user.phone.startsWith('+') ? user.phone : '+${user.phone}';
                }()),
                const SizedBox(height: 12),
                _buildInfoRow(LucideIcons.shield, 'Role', () {
                  final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
                  return user.role.toUpperCase();
                }()),
                const SizedBox(height: 12),
                _buildInfoRow(LucideIcons.activity, 'Status', () {
                  final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
                  return user.status.toUpperCase();
                }()),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                    ),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _saving = true;
                        context.read<AuthBloc>().add(UpdateProfileRequested({
                          'full_name': _nameController.text.trim(),
                          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                        }));
                      }
                    },
                    child: const Text('SAVE CHANGES'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: label == 'Status' ? AppColors.success : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
