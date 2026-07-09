import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'wallet_screen.dart';
import 'package:barbar_app/presentation/bloc/address/address_bloc.dart';
import 'package:barbar_app/presentation/bloc/address/address_event.dart';
import 'package:barbar_app/presentation/bloc/address/address_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthBloc>().add(LogoutRequested());
                      },
                      child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _ProfileContent(user: state.user);
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final completion = _profileCompletion(user);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Avatar + Name
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('+${user.phone}', style: const TextStyle(color: AppColors.textSecondary)),
              if (user.email != null && user.email!.isNotEmpty)
                Text(user.email!, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Profile Completion
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile Completion', style: Theme.of(context).textTheme.titleMedium),
                  Text('$completion%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  backgroundColor: AppColors.surface,
                  color: AppColors.primary,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              _completionItem('Full Name', user.fullName.isNotEmpty, Icons.check, Icons.close),
              _completionItem('Phone Number', user.phone.isNotEmpty, Icons.check, Icons.close),
              _completionItem('Email Address', user.email != null && user.email!.isNotEmpty, Icons.check, Icons.close),
              _completionItem('Avatar', user.avatar != null && user.avatar!.isNotEmpty, Icons.check, Icons.close),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Menu options
        _menuItem(context, LucideIcons.wallet, 'Wallet', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
        _menuItem(context, LucideIcons.mapPin, 'My Addresses', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AddressListScreen()))),
        _menuItem(context, LucideIcons.settings, 'Account Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _EditProfileScreen()))),
      ],
    );
  }

  int _profileCompletion(UserModel u) {
    int score = 0;
    if (u.fullName.isNotEmpty) score += 25;
    if (u.phone.isNotEmpty) score += 25;
    if (u.email != null && u.email!.isNotEmpty) score += 25;
    if (u.avatar != null && u.avatar!.isNotEmpty) score += 25;
    return score;
  }

  Widget _completionItem(String label, bool isComplete, IconData checkIcon, IconData closeIcon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isComplete ? checkIcon : closeIcon, size: 16, color: isComplete ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isComplete ? AppColors.textPrimary : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
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

  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _nameController = TextEditingController(text: user.fullName);
    _emailController = TextEditingController(text: user.email ?? '');
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
      appBar: AppBar(title: const Text('ACCOUNT SETTINGS')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
            );
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(LucideIcons.user)),
                  validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(LucideIcons.mail)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Phone: +${(context.read<AuthBloc>().state as AuthAuthenticated).user.phone}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      context.read<AuthBloc>().add(UpdateProfileRequested({
                        'full_name': _nameController.text.trim(),
                        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                      }));
                    }
                  },
                  child: const Text('SAVE CHANGES'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressListScreen extends StatefulWidget {
  const _AddressListScreen();

  @override
  State<_AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<_AddressListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(FetchAddresses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY ADDRESSES')),
      body: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is AddressFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.error, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          if (state is AddressesLoaded) {
            final addresses = state.addresses;
            if (addresses.isEmpty) {
              return const Center(child: Text('No saved addresses'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                final isDefault = addr['is_default'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDefault ? AppColors.primary : AppColors.border),
                  ),
                  child: ListTile(
                    leading: Icon(isDefault ? LucideIcons.home : LucideIcons.mapPin,
                        color: isDefault ? AppColors.primary : AppColors.textSecondary),
                    title: Text(addr['title'] ?? 'Address'),
                    subtitle: Text('${addr['street'] ?? ""}, ${addr['city'] ?? ""}'),
                    trailing: isDefault
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Default', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          )
                        : null,
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
