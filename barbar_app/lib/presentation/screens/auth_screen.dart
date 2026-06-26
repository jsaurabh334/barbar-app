import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../widgets/glass_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  // Input Controllers
  final _loginPhoneController = TextEditingController(text: '+91');
  final _signUpPhoneController = TextEditingController(text: '+91');
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  String _selectedRole = 'customer'; // customer, barber, vendor, delivery, admin
  String? _pendingPhone; // Holds phone number during OTP flow

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _signUpPhoneController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background subtle ambient gradients
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.3,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is OtpSentSuccess) {
                  setState(() {
                    _pendingPhone = state.phone;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OTP verification code sent!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Brand Logo
                        const Icon(
                          LucideIcons.scissors,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'BARBAR',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            letterSpacing: 4.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Hyperlocal Salons & Grooming Marketplace',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Form Section
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _pendingPhone != null
                              ? _buildOtpWidget(state)
                              : _buildAuthTabsWidget(state),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTabsWidget(AuthState state) {
    return GlassCard(
      key: const ValueKey('auth_tabs'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'LOGIN'),
              Tab(text: 'REGISTER'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 380, // Safe bounds for form fields
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginForm(state),
                _buildSignUpForm(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AuthState state) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Verify with OTP to access your queues, orders, and wallet.'),
          const SizedBox(height: 32),
          TextFormField(
            controller: _loginPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(LucideIcons.phone, size: 20),
            ),
            validator: (val) {
              if (val == null || val.length < 10) {
                return 'Please enter a valid phone number with country code';
              }
              return null;
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: state is AuthLoading ? null : _submitLogin,
            child: state is AuthLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SEND OTP'),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state is AuthLoading
                ? null
                : () {
                    _loginPhoneController.text = '+919999999999';
                    _submitLogin();
                  },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.playCircle, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text('TEST PROFILE LOGIN (NO OTP)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(AuthState state) {
    return Form(
      key: _signUpFormKey,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(LucideIcons.user, size: 20),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Name required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(LucideIcons.phone, size: 20),
            ),
            validator: (val) => val == null || val.length < 10 ? 'Phone invalid' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signUpPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(LucideIcons.lock, size: 20),
            ),
            validator: (val) => val == null || val.length < 6 ? 'Password min 6 chars' : null,
          ),
          const SizedBox(height: 16),
          // Role selection segmented chip style
          Text('Register as:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRoleChip('customer', 'Customer'),
              _buildRoleChip('barber', 'Barber'),
              _buildRoleChip('vendor', 'Vendor'),
              _buildRoleChip('delivery', 'Delivery'),
              _buildRoleChip('admin', 'Admin'),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: state is AuthLoading ? null : _submitSignUp,
            child: state is AuthLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('CREATE ACCOUNT'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, String label) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textSecondary,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRole = role;
          });
        }
      },
    );
  }

  Widget _buildOtpWidget(AuthState state) {
    return GlassCard(
      key: const ValueKey('otp_widget'),
      child: Form(
        key: _otpFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () {
                    setState(() {
                      _pendingPhone = null;
                      _otpController.clear();
                    });
                  },
                ),
                Text(
                  'Verify OTP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A verification code has been sent to $_pendingPhone. Enter code below.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
              ),
              maxLength: 6,
              validator: (val) {
                if (val == null || val.length != 6) {
                  return 'Enter the 6-digit OTP code';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state is AuthLoading ? null : _submitOtp,
              child: state is AuthLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('VERIFY & CONTINUE'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: state is AuthLoading
                  ? null
                  : () {
                      context.read<AuthBloc>().add(SendOtpRequested(_pendingPhone!));
                    },
              child: const Text(
                'RESEND CODE',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitLogin() {
    if (_loginFormKey.currentState?.validate() ?? false) {
      final phone = _loginPhoneController.text.trim();
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      
      final isTestPhone = cleanPhone == '+919999999999' ||
          cleanPhone == '+918888888888' ||
          cleanPhone == '+917777777777' ||
          cleanPhone == '+916666666666' ||
          cleanPhone == '+915555555555';

      if (isTestPhone) {
        context.read<AuthBloc>().add(VerifyOtpRequested(phone: phone, otp: '123456'));
      } else {
        context.read<AuthBloc>().add(SendOtpRequested(phone));
      }
    }
  }

  void _submitSignUp() {
    if (_signUpFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              fullName: _signUpNameController.text.trim(),
              phone: _signUpPhoneController.text.trim(),
              password: _signUpPasswordController.text,
              role: _selectedRole,
            ),
          );
    }
  }

  void _submitOtp() {
    if (_otpFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            VerifyOtpRequested(
              phone: _pendingPhone!,
              otp: _otpController.text.trim(),
            ),
          );
    }
  }
}
