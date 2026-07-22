import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/delivery/delivery_bloc.dart';
import '../../bloc/delivery/delivery_event.dart';
import '../../bloc/delivery/delivery_state.dart';

class DeliveryBankScreen extends StatefulWidget {
  const DeliveryBankScreen({super.key});

  @override
  State<DeliveryBankScreen> createState() => _DeliveryBankScreenState();
}

class _DeliveryBankScreenState extends State<DeliveryBankScreen> {
  bool _editing = false;
  Map<String, dynamic>? _account;

  final _nameCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DeliveryBloc>().add(FetchBankAccount());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    _bankCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  void _startEdit() {
    _nameCtrl.text = _account?['account_holder_name'] ?? '';
    _accCtrl.text = _account?['account_number'] ?? '';
    _ifscCtrl.text = _account?['ifsc_code'] ?? '';
    _bankCtrl.text = _account?['bank_name'] ?? '';
    _branchCtrl.text = _account?['branch_name'] ?? '';
    _upiCtrl.text = _account?['upi_id'] ?? '';
    setState(() => _editing = true);
  }

  void _save() {
    context.read<DeliveryBloc>().add(SaveBankAccount({
      'account_holder_name': _nameCtrl.text.trim(),
      'account_number': _accCtrl.text.trim(),
      'ifsc_code': _ifscCtrl.text.trim(),
      'bank_name': _bankCtrl.text.trim(),
      'branch_name': _branchCtrl.text.trim(),
      'upi_id': _upiCtrl.text.trim(),
    }));
  }

  void _delete() {
    final bloc = context.read<DeliveryBloc>();
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Bank Account?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure? This action cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        bloc.add(DeleteBankAccount());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryBloc, DeliveryState>(
      listener: (context, state) {
        if (state is DeliveryBankAccountLoaded) {
          setState(() => _account = state.account);
        } else if (state is DeliverySuccess) {
          if (state.message == 'Bank account saved') {
            context.read<DeliveryBloc>().add(FetchBankAccount());
            setState(() => _editing = false);
          } else if (state.message == 'Bank account deleted') {
            setState(() { _account = null; _editing = false; });
          }
        }
      },
      builder: (context, state) {
        if (state is DeliveryLoading && _account == null && !_editing) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_editing ? 'Edit Bank Account' : 'Bank Account'),
            actions: [
              if (!_editing && _account != null)
                IconButton(icon: const Icon(LucideIcons.pencil), onPressed: _startEdit),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _editing ? _buildForm() : _buildDetails(),
          ),
        );
      },
    );
  }

  Widget _buildDetails() {
    if (_account == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.building2, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('No bank account added', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startEdit,
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Bank Account'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _detailRow('Account Holder', _account!['account_holder_name'] ?? ''),
              const Divider(color: AppColors.border),
              _detailRow('Account Number', _maskAccount(_account!['account_number'] ?? '')),
              const Divider(color: AppColors.border),
              _detailRow('IFSC Code', _account!['ifsc_code'] ?? ''),
              const Divider(color: AppColors.border),
              _detailRow('Bank Name', _account!['bank_name'] ?? ''),
              if (_account!['branch_name'] != null) ...[
                const Divider(color: AppColors.border),
                _detailRow('Branch', _account!['branch_name']),
              ],
              if (_account!['upi_id'] != null && _account!['upi_id'].toString().isNotEmpty) ...[
                const Divider(color: AppColors.border),
                _detailRow('UPI ID', _account!['upi_id']),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_account!['is_verified'] == true)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text('Account verified', style: TextStyle(color: AppColors.success)),
              ],
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _delete,
          icon: const Icon(LucideIcons.trash2, color: AppColors.error),
          label: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('Account Holder Name', _nameCtrl, LucideIcons.user),
        const SizedBox(height: 16),
        _field('Account Number', _accCtrl, LucideIcons.hash, kt: TextInputType.number),
        const SizedBox(height: 16),
        _field('IFSC Code', _ifscCtrl, LucideIcons.fileText),
        const SizedBox(height: 16),
        _field('Bank Name', _bankCtrl, LucideIcons.building2),
        const SizedBox(height: 16),
        _field('Branch Name', _branchCtrl, LucideIcons.mapPin),
        const SizedBox(height: 16),
        _field('UPI ID', _upiCtrl, LucideIcons.smartphone),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Save', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _editing = false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? kt}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: kt,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _maskAccount(String acc) {
    if (acc.length <= 4) return acc;
    return 'XXXX${acc.substring(acc.length - 4)}';
  }
}
