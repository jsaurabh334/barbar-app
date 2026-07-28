import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/barber_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../barber_profile_screen.dart';
import '../barber_staff_screen.dart';

class BarberSettingsScreen extends StatefulWidget {
  final BarberRepository barberRepository;

  const BarberSettingsScreen({Key? key, required this.barberRepository}) : super(key: key);

  @override
  State<BarberSettingsScreen> createState() => _BarberSettingsScreenState();
}

class _BarberSettingsScreenState extends State<BarberSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Shop Settings State
  bool _isAvailable = true;
  bool _homeServiceAvailable = false;
  final TextEditingController _radiusController = TextEditingController(text: '5');
  final TextEditingController _baseChargeController = TextEditingController(text: '50');
  final TextEditingController _perKmChargeController = TextEditingController(text: '10');

  // Local Preferences State
  bool _pushNotifications = true;
  bool _soundAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _baseChargeController.dispose();
    _perKmChargeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushNotifications = prefs.getBool('barber_push_notifications') ?? true;
      _soundAlerts = prefs.getBool('barber_sound_alerts') ?? true;

      final res = await widget.barberRepository.getProfile();
      final data = (res['data'] as Map<String, dynamic>?) ?? res;

      setState(() {
        _isAvailable = (data['is_available'] as bool?) ?? (data['isAvailable'] as bool?) ?? true;
        _homeServiceAvailable = (data['is_home_service_available'] as bool?) ?? (data['isHomeServiceAvailable'] as bool?) ?? false;
        
        final radius = data['service_radius_km'] ?? data['serviceRadiusKm'];
        if (radius != null) _radiusController.text = radius.toString();

        final baseCharge = data['base_travel_charge'] ?? data['baseTravelCharge'];
        if (baseCharge != null) _baseChargeController.text = baseCharge.toString();

        final perKm = data['travel_charge_per_km'] ?? data['travelChargePerKm'];
        if (perKm != null) _perKmChargeController.text = perKm.toString();

        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('barber_push_notifications', _pushNotifications);
    await prefs.setBool('barber_sound_alerts', _soundAlerts);
  }

  Future<void> _saveShopSettings() async {
    setState(() => _isSaving = true);
    try {
      await _savePreferences();

      final radius = double.tryParse(_radiusController.text.trim()) ?? 5.0;
      final baseCharge = double.tryParse(_baseChargeController.text.trim()) ?? 50.0;
      final perKmCharge = double.tryParse(_perKmChargeController.text.trim()) ?? 10.0;

      await widget.barberRepository.updateProfile({
        'is_home_service_available': _homeServiceAvailable,
        'service_radius_km': radius,
        'base_travel_charge': baseCharge,
        'travel_charge_per_km': perKmCharge,
      });

      await widget.barberRepository.updateAvailability(
        isAvailable: _isAvailable,
        status: _isAvailable ? 'active' : 'offline',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully!', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Barber Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveShopSettings,
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
              label: Text(
                'Save',
                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Section 1: Availability & Status ---
                  _buildSectionHeader('Availability & Status', LucideIcons.power),
                  const SizedBox(height: 10),
                  _buildCardContainer([
                    SwitchListTile(
                      activeColor: AppColors.success,
                      title: Text('Shop Online Status', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text(
                        _isAvailable ? 'Visible to clients on map and accepting bookings' : 'Offline - hidden from discovery',
                        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      value: _isAvailable,
                      onChanged: (val) {
                        setState(() => _isAvailable = val);
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: Text('Home Service', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text(
                        'Provide haircut & grooming services at client location',
                        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      value: _homeServiceAvailable,
                      onChanged: (val) {
                        setState(() => _homeServiceAvailable = val);
                      },
                    ),
                  ]),

                  // --- Section 2: Home Service Configuration ---
                  if (_homeServiceAvailable) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Home Service Pricing & Radius', LucideIcons.mapPin),
                    const SizedBox(height: 10),
                    _buildCardContainer([
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _radiusController,
                              label: 'Service Radius (KM)',
                              hint: 'e.g. 5',
                              icon: LucideIcons.navigation,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _baseChargeController,
                              label: 'Base Travel Fee (₹)',
                              hint: 'e.g. 50',
                              icon: LucideIcons.indianRupee,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _perKmChargeController,
                              label: 'Extra Charge / KM (₹)',
                              hint: 'e.g. 10',
                              icon: LucideIcons.bike,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 24),

                  // --- Section 3: App & Notification Preferences ---
                  _buildSectionHeader('App & Notification Preferences', LucideIcons.bell),
                  const SizedBox(height: 10),
                  _buildCardContainer([
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: Text('Push Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text('Receive instant alerts for new bookings & queue updates', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      value: _pushNotifications,
                      onChanged: (val) {
                        setState(() => _pushNotifications = val);
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: Text('Booking Sound Alerts', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text('Play loud sound chime when new client checks in', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      value: _soundAlerts,
                      onChanged: (val) {
                        setState(() => _soundAlerts = val);
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // --- Section 4: Quick Shortcuts ---
                  _buildSectionHeader('Management Shortcuts', LucideIcons.layers),
                  const SizedBox(height: 10),
                  _buildCardContainer([
                    ListTile(
                      leading: const Icon(LucideIcons.user, color: AppColors.primary),
                      title: Text('Edit Shop Profile & Media', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text('Update shop name, photos, address & timings', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BarberProfileScreen(barberRepository: widget.barberRepository)));
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    ListTile(
                      leading: const Icon(LucideIcons.users, color: AppColors.primary),
                      title: Text('Staff & Barber Management', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Text('Add chairs, staff barbers & specializations', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BarberStaffScreen()));
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // --- Section 5: Account & Logout ---
                  _buildCardContainer([
                    ListTile(
                      leading: const Icon(LucideIcons.logOut, color: AppColors.error),
                      title: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.error)),
                      subtitle: Text('Sign out of your barber management session', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                      onTap: () {
                        context.read<AuthBloc>().add(LogoutRequested());
                        Navigator.pop(context);
                      },
                    ),
                  ]),

                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Barbar App v1.0.0 (Build 2026)',
                      style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}
