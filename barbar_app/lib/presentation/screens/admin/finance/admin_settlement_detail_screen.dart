import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barbar_app/core/theme/app_theme.dart';
import 'package:barbar_app/data/models/settlement_model.dart';
import 'package:barbar_app/presentation/bloc/admin/admin_settlements_bloc.dart';
import 'package:barbar_app/presentation/widgets/admin/admin_status_badge.dart';

class AdminSettlementDetailScreen extends StatelessWidget {
  final SettlementModel settlement;
  const AdminSettlementDetailScreen({super.key, required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settlement Detail')),
      body: BlocListener<AdminSettlementsBloc, AdminSettlementsState>(
        listener: (context, state) {
          if (state is AdminSettlementActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success));
            Navigator.pop(context);
          } else if (state is AdminSettlementsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(context),
              const SizedBox(height: 20),
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildAmountBreakdown(),
              if (settlement.status == 'pending') ...[
                const SizedBox(height: 24),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(settlement.businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AdminStatusBadge(label: settlement.status),
          const SizedBox(height: 12),
          Text('₹${settlement.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 4),
          const Text('Settlement Amount', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DETAILS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.primary)),
          const Divider(height: 20),
          _infoRow('Vendor', settlement.businessName),
          _infoRow('Settlement ID', settlement.id),
          _infoRow('Status', settlement.status.toUpperCase()),
          _infoRow('Date', '${settlement.createdAt.day}/${settlement.createdAt.month}/${settlement.createdAt.year}'),
          if (settlement.processedAt != null) _infoRow('Processed At', '${settlement.processedAt!.day}/${settlement.processedAt!.month}/${settlement.processedAt!.year}'),
          if (settlement.utrNumber != null) _infoRow('UTR Number', settlement.utrNumber!),
          if (settlement.bankAccount != null) _infoRow('Bank Account', settlement.bankAccount!),
        ],
      ),
    );
  }

  Widget _buildAmountBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AMOUNT BREAKDOWN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.primary)),
          const Divider(height: 20),
          _infoRow('Gross Amount', '₹${settlement.amount.toStringAsFixed(2)}'),
          _infoRow('Platform Fee', '- ₹${settlement.feeAmount.toStringAsFixed(2)}', valueColor: AppColors.error),
          const Divider(height: 12),
          _infoRow('Net Amount', '₹${settlement.netAmount.toStringAsFixed(2)}', valueColor: AppColors.success, bold: true),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final utrController = TextEditingController();
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(LucideIcons.checkCircle),
          label: const Text('APPROVE SETTLEMENT', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _processWithUTR(context, 'approved', utrController),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(LucideIcons.xCircle),
          label: const Text('REJECT SETTLEMENT', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _processWithUTR(context, 'rejected', utrController),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(LucideIcons.send),
          label: const Text('PROCESS (MARK AS PAID)', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _processWithUTR(context, 'processed', utrController),
        ),
      ],
    );
  }

  void _processWithUTR(BuildContext context, String status, TextEditingController utrController) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${status.toUpperCase()} Settlement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter UTR number for transaction reference:'),
            const SizedBox(height: 12),
            TextField(
              controller: utrController,
              decoration: const InputDecoration(
                labelText: 'UTR Number (optional)',
                hintText: 'e.g. HDFC123456789',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminSettlementsBloc>().add(ProcessSettlement(
                id: settlement.id,
                status: status,
                utrNumber: utrController.text.isNotEmpty ? utrController.text : null,
              ));
            },
            child: Text(status.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
