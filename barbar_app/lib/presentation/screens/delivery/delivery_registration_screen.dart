import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/repositories/delivery_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class DeliveryRegistrationScreen extends StatefulWidget {
  const DeliveryRegistrationScreen({super.key});

  @override
  State<DeliveryRegistrationScreen> createState() => _DeliveryRegistrationScreenState();
}

class _DeliveryRegistrationScreenState extends State<DeliveryRegistrationScreen> {
  int _step = 0;
  bool _loading = false;

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _fullNameCtrl.text = user.fullName;
      _phoneCtrl.text = user.phone;
      if (user.email != null && user.email!.isNotEmpty) {
        _emailCtrl.text = user.email!;
      }
    }
  }
  final _vehicleTypeCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  final _licenseNumberCtrl = TextEditingController();
  final _accHolderCtrl = TextEditingController();
  final _accNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  String? _panFrontPath;
  String? _aadhaarFrontPath;
  String? _aadhaarBackPath;
  String? _drivingLicensePath;

  final List<String> _vehicleTypes = ['Bike', 'Scooter', 'Car', 'Van', 'Truck'];
  String? _selectedVehicleType;

  List<String> get _steps => ['Basic', 'Vehicle', 'Bank', 'KYC', 'Review'];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _accHolderCtrl.dispose();
    _accNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        switch (type) {
          case 'pan': _panFrontPath = file.path; break;
          case 'aadhaar_front': _aadhaarFrontPath = file.path; break;
          case 'aadhaar_back': _aadhaarBackPath = file.path; break;
          case 'license': _drivingLicensePath = file.path; break;
        }
      });
    }
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        return _fullNameCtrl.text.trim().isNotEmpty &&
            _phoneCtrl.text.trim().isNotEmpty &&
            _emailCtrl.text.trim().isNotEmpty;
      case 1:
        return _selectedVehicleType != null &&
            _vehicleNumberCtrl.text.trim().isNotEmpty &&
            _licenseNumberCtrl.text.trim().isNotEmpty;
      case 2:
        return _accHolderCtrl.text.trim().isNotEmpty &&
            _accNumberCtrl.text.trim().isNotEmpty &&
            _ifscCtrl.text.trim().isNotEmpty &&
            _bankNameCtrl.text.trim().isNotEmpty;
      case 3:
        return _panFrontPath != null && _drivingLicensePath != null;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    if (!_validateStep()) return;

    if (_step < 4) {
      setState(() => _step++);
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = context.read<DeliveryRepository>();
      await repo.register({
        'vehicle_type': _selectedVehicleType,
        'vehicle_number': _vehicleNumberCtrl.text.trim(),
        'license_number': _licenseNumberCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration submitted for approval!'), backgroundColor: AppColors.success),
      );
      context.read<AuthBloc>().add(LogoutRequested());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery Partner Registration'),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 24),
            if (_step == 0) _buildBasicInfoStep(),
            if (_step == 1) _buildVehicleStep(),
            if (_step == 2) _buildBankStep(),
            if (_step == 3) _buildKycStep(),
            if (_step == 4) _buildReviewStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < _step ? AppColors.primary : AppColors.border,
            ),
          );
        }
        final idx = i ~/ 2;
        final active = idx <= _step;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : AppColors.surface,
            border: Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Text('${idx + 1}',
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              )),
        );
      }),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {TextInputType? kt, bool readOnly = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: kt,
      readOnly: readOnly,
      onChanged: readOnly ? null : (_) => setState(() {}),
      style: TextStyle(color: readOnly ? AppColors.textSecondary : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
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
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Basic Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Enter your personal details', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        _buildTextField('Full Name', _fullNameCtrl, LucideIcons.user, readOnly: true),
        const SizedBox(height: 16),
        _buildTextField('Phone Number', _phoneCtrl, LucideIcons.phone, kt: TextInputType.phone, readOnly: true),
        const SizedBox(height: 16),
        _buildTextField('Email Address', _emailCtrl, LucideIcons.mail, kt: TextInputType.emailAddress, readOnly: true),
        const SizedBox(height: 24),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildVehicleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Vehicle Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Enter your delivery vehicle information', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _selectedVehicleType,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Vehicle Type',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(LucideIcons.truck, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
          ),
          items: _vehicleTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _selectedVehicleType = v),
        ),
        const SizedBox(height: 16),
        _buildTextField('Vehicle Number', _vehicleNumberCtrl, LucideIcons.hash),
        const SizedBox(height: 16),
        _buildTextField('License Number', _licenseNumberCtrl, LucideIcons.fileText),
        const SizedBox(height: 24),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildBankStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Bank Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('For payout settlements', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        _buildTextField('Account Holder Name', _accHolderCtrl, LucideIcons.user),
        const SizedBox(height: 16),
        _buildTextField('Account Number', _accNumberCtrl, LucideIcons.hash, kt: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextField('IFSC Code', _ifscCtrl, LucideIcons.fileText),
        const SizedBox(height: 16),
        _buildTextField('Bank Name', _bankNameCtrl, LucideIcons.building2),
        const SizedBox(height: 24),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildKycStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('KYC Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Upload documents for verification', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        _buildDocPicker('PAN Card', _panFrontPath, 'pan'),
        const SizedBox(height: 12),
        _buildDocPicker('Aadhaar Card (Front)', _aadhaarFrontPath, 'aadhaar_front'),
        const SizedBox(height: 12),
        _buildDocPicker('Aadhaar Card (Back)', _aadhaarBackPath, 'aadhaar_back'),
        const SizedBox(height: 12),
        _buildDocPicker('Driving License', _drivingLicensePath, 'license'),
        const SizedBox(height: 24),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildDocPicker(String label, String? path, String type) {
    return InkWell(
      onTap: () => _pickImage(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: path != null ? AppColors.success : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(path != null ? LucideIcons.checkCircle : LucideIcons.upload,
                color: path != null ? AppColors.success : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
            if (path != null)
              Text('Uploaded', style: TextStyle(color: AppColors.success, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Review Your Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Please verify all information before submitting', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        _buildReviewSection('Personal', [
          _reviewTile('Name', _fullNameCtrl.text),
          _reviewTile('Phone', _phoneCtrl.text),
          _reviewTile('Email', _emailCtrl.text),
        ]),
        const SizedBox(height: 12),
        _buildReviewSection('Vehicle', [
          _reviewTile('Type', _selectedVehicleType ?? ''),
          _reviewTile('Number', _vehicleNumberCtrl.text),
          _reviewTile('License', _licenseNumberCtrl.text),
        ]),
        const SizedBox(height: 12),
        _buildReviewSection('Bank', [
          _reviewTile('Holder', _accHolderCtrl.text),
          _reviewTile('Account', _accNumberCtrl.text),
          _reviewTile('IFSC', _ifscCtrl.text),
          _reviewTile('Bank', _bankNameCtrl.text),
        ]),
        const SizedBox(height: 12),
        _buildReviewSection('Documents', [
          _reviewTile('PAN Card', _panFrontPath != null ? 'Uploaded' : 'Missing'),
          _reviewTile('Aadhaar Front', _aadhaarFrontPath != null ? 'Uploaded' : 'Missing'),
          _reviewTile('Aadhaar Back', _aadhaarBackPath != null ? 'Uploaded' : 'Missing'),
          _reviewTile('Driving License', _drivingLicensePath != null ? 'Uploaded' : 'Missing'),
        ]),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Registration', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Divider(color: AppColors.border),
          ...children,
        ],
      ),
    );
  }

  Widget _reviewTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _validateStep() ? _submit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('Next', style: const TextStyle(fontSize: 16)),
    );
  }
}
