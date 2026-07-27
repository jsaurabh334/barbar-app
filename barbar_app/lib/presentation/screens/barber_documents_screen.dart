import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _pickedImageFile;
  bool _useImagePicker = true; // true = image upload, false = URL input

  static const docTypes = [
    'Aadhaar Card',
    'PAN Card',
    'GST Certificate',
    'Shop License',
    'Shop Photo',
    'Selfie',
  ];

  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _pickedImageFile = File(picked.path);
        _docUrlController.text = picked.path; // use local path as placeholder URL
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Select Image Source', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      icon: LucideIcons.camera,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSourceOption(
                      icon: LucideIcons.image,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_docTypeController.text.isEmpty) return;

    // Determine the URL to submit
    String docUrl = _docUrlController.text.trim();
    if (_pickedImageFile != null && _useImagePicker) {
      // Use the local file path as document URL (the backend handles file upload)
      docUrl = _pickedImageFile!.path;
    }

    if (docUrl.isEmpty) return;

    if (_editingDocId != null) {
      context.read<BarberDocumentsBloc>().add(ReplaceDocument(
        docId: _editingDocId!,
        docType: _docTypeController.text,
        docUrl: docUrl,
      ));
    } else {
      context.read<BarberDocumentsBloc>().add(UploadDocument(
        docType: _docTypeController.text,
        docUrl: docUrl,
      ));
    }
    _docTypeController.clear();
    _docUrlController.clear();
    setState(() {
      _editingDocId = null;
      _pickedImageFile = null;
    });
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
                      Text(
                        _editingDocId != null ? 'REPLACE DOCUMENT' : 'ADD DOCUMENT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      // Document Type Dropdown
                      DropdownButtonFormField<String>(
                        value: docTypes.contains(_docTypeController.text) ? _docTypeController.text : null,
                        dropdownColor: AppColors.surface,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                          prefixIcon: Icon(LucideIcons.fileText, size: 18),
                        ),
                        items: docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _docTypeController.text = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Toggle: Image Upload vs URL
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _useImagePicker = true;
                                    _docUrlController.clear();
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _useImagePicker ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.image, size: 15, color: _useImagePicker ? Colors.black : AppColors.textSecondary),
                                        const SizedBox(width: 5),
                                        Text('Upload Image', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _useImagePicker ? Colors.black : AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _useImagePicker = false;
                                    _pickedImageFile = null;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_useImagePicker ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.link, size: 15, color: !_useImagePicker ? Colors.black : AppColors.textSecondary),
                                        const SizedBox(width: 5),
                                        Text('Enter URL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: !_useImagePicker ? Colors.black : AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Conditional: Image Picker or URL Input
                      if (_useImagePicker) ...[
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _pickedImageFile != null ? AppColors.primary : AppColors.border,
                                width: _pickedImageFile != null ? 2 : 1,
                              ),
                            ),
                            child: _pickedImageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(_pickedImageFile!, fit: BoxFit.cover),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(() => _pickedImageFile = null),
                                            child: Container(
                                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(13), bottomRight: Radius.circular(13)),
                                            ),
                                            child: const Text('Tap to change', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.uploadCloud, size: 32, color: AppColors.primary),
                                      const SizedBox(height: 10),
                                      const Text('Tap to select image', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      const Text('Camera or Gallery', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    ],
                                  ),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _docUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Document URL',
                            hintText: 'https://example.com/document.jpg',
                            prefixIcon: Icon(LucideIcons.link, size: 18),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _submit,
                          icon: isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(LucideIcons.upload, size: 16, color: Colors.black),
                          label: Text(
                            _editingDocId != null ? 'REPLACE DOCUMENT' : 'SAVE DOCUMENT',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
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
                        // Thumbnail if image URL
                        if ((doc['doc_url'] as String? ?? '').isNotEmpty)
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                doc['doc_url'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(LucideIcons.fileText, size: 24, color: AppColors.primary),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['doc_type'] as String? ?? 'Document', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${doc['status'] as String? ?? 'pending'}',
                                style: TextStyle(color: _statusColor(doc['status'] as String?), fontSize: 12),
                              ),
                              if (doc['remarks'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Reason: ${doc['remarks'] as String}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(_statusIcon(doc['status'] as String?), style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.primary),
                          tooltip: 'Replace',
                          onPressed: () {
                            setState(() {
                              _editingDocId = doc['id'] as String?;
                              _docTypeController.text = doc['doc_type'] as String? ?? '';
                              _docUrlController.clear();
                              _pickedImageFile = null;
                            });
                          },
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
