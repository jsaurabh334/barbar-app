import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/barber_documents/barber_documents_bloc.dart';
import '../bloc/barber_documents/barber_documents_event.dart';
import '../bloc/barber_documents/barber_documents_state.dart';
import '../widgets/glass_card.dart';

class BarberDocumentsScreen extends StatefulWidget {
  const BarberDocumentsScreen({super.key});

  @override
  State<BarberDocumentsScreen> createState() => _BarberDocumentsScreenState();
}

class _BarberDocumentsScreenState extends State<BarberDocumentsScreen> {
  final _docTypeController = TextEditingController();
  final _docUrlController = TextEditingController();
  String? _editingDocId;

  static const docTypes = ['Aadhaar Card', 'PAN Card', 'GST Certificate', 'Shop License', 'Shop Photo', 'Selfie'];

  @override
  void initState() {
    super.initState();
    context.read<BarberDocumentsBloc>().add(FetchDocuments());
  }

  @override
  void dispose() {
    _docTypeController.dispose();
    _docUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_docTypeController.text.isEmpty || _docUrlController.text.isEmpty) return;
    if (_editingDocId != null) {
      context.read<BarberDocumentsBloc>().add(ReplaceDocument(
        docId: _editingDocId!,
        docType: _docTypeController.text,
        docUrl: _docUrlController.text,
      ));
    } else {
      context.read<BarberDocumentsBloc>().add(UploadDocument(
        docType: _docTypeController.text,
        docUrl: _docUrlController.text,
      ));
    }
    _docTypeController.clear();
    _docUrlController.clear();
    _editingDocId = null;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  String _statusIcon(String? status) {
    switch (status) {
      case 'approved': return '✅';
      case 'rejected': return '❌';
      default: return '⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DOCUMENTS')),
      body: BlocConsumer<BarberDocumentsBloc, BarberDocumentsState>(
        listener: (context, state) {
          if (state is BarberDocumentsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
          } else if (state is BarberDocumentsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final docs = state is BarberDocumentsLoaded ? state.documents : <Map<String, dynamic>>[];
          final isLoading = state is BarberDocumentsLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ADD / REPLACE DOCUMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: docTypes.contains(_docTypeController.text) ? _docTypeController.text : null,
                        dropdownColor: AppColors.surface,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                          prefixIcon: Icon(LucideIcons.fileText, size: 18),
                        ),
                        items: docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) { if (val != null) _docTypeController.text = val; },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _docUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Document URL',
                          prefixIcon: Icon(LucideIcons.link, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: Text(_editingDocId != null ? 'REPLACE DOCUMENT' : 'UPLOAD DOCUMENT'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('UPLOADED DOCUMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                const SizedBox(height: 12),
                if (isLoading && docs.isEmpty)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (docs.isEmpty)
                  const Text('No documents uploaded yet', style: TextStyle(color: AppColors.textSecondary))
                else
                  ...docs.map((doc) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['doc_type'] as String? ?? 'Document', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Status: ${doc['status'] as String? ?? 'pending'}',
                                style: TextStyle(color: _statusColor(doc['status'] as String?), fontSize: 12)),
                              if (doc['remarks'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Reason: ${doc['remarks'] as String}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ),
                            ],
                          ),
                        ),
                        Text(_statusIcon(doc['status'] as String?), style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.primary),
                          onPressed: () {
                            _editingDocId = doc['id'] as String?;
                            _docTypeController.text = doc['doc_type'] as String? ?? '';
                            _docUrlController.clear();
                          },
                          tooltip: 'Replace',
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}
