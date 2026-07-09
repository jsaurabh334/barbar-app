import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/review_model.dart';
import '../../domain/repositories/review_repository.dart';
import '../bloc/review/review_bloc.dart';
import '../bloc/review/review_event.dart';
import '../bloc/review/review_state.dart';
import '../widgets/rating_bar.dart';

class _ImageItem {
  final File file;
  String? url;
  bool isUploading = false;
  bool hasFailed = false;

  _ImageItem({required this.file, this.url});
}

class ReviewScreen extends StatefulWidget {
  final String bookingId;
  final String shopName;
  final ReviewModel? review;
  final bool isEdit;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.shopName,
    this.review,
  }) : isEdit = review != null;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late int _rating;
  late TextEditingController _commentController;
  late bool _isAnonymous;
  final List<_ImageItem> _images = [];
  final _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.review?.rating ?? 0;
    _commentController = TextEditingController(text: widget.review?.comment ?? '');
    _isAnonymous = widget.review?.isAnonymous ?? false;
    if (widget.review != null) {
      for (final img in widget.review!.images) {
        _images.add(_ImageItem(file: File(''), url: img.url));
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920);
    if (picked != null) {
      setState(() => _images.add(_ImageItem(file: File(picked.path))));
    }
  }

  Future<void> _uploadImages() async {
    setState(() => _isUploading = true);
    final repo = context.read<ReviewRepository>();
    for (final item in _images) {
      if (item.url != null || item.isUploading) continue;
      item.isUploading = true;
      item.hasFailed = false;
      setState(() {});
      try {
        final result = await repo.uploadImage(item.file, onProgress: (sent, total) {
          setState(() {});
        });
        item.url = result['url'] as String;
        item.isUploading = false;
        setState(() {});
      } catch (_) {
        item.isUploading = false;
        item.hasFailed = true;
        setState(() {});
      }
    }
    setState(() => _isUploading = false);
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _retryUpload(int index) async {
    final item = _images[index];
    if (item.url != null || item.file.path.isEmpty) return;
    item.isUploading = true;
    item.hasFailed = false;
    setState(() {});
    try {
      final repo = context.read<ReviewRepository>();
      final result = await repo.uploadImage(item.file);
      item.url = result['url'] as String;
      item.isUploading = false;
      setState(() {});
    } catch (_) {
      item.isUploading = false;
      item.hasFailed = true;
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    await _uploadImages();
    if (!mounted) return;
    final imageUrls = _images.where((i) => i.url != null).map((i) => {'url': i.url!}).toList();
    if (widget.isEdit) {
      context.read<ReviewBloc>().add(
        UpdateReview(
          reviewId: widget.review!.id,
          rating: _rating,
          comment: _commentController.text.trim(),
          isAnonymous: _isAnonymous,
          images: imageUrls,
        ),
      );
    } else {
      context.read<ReviewBloc>().add(
        CreateReview(
          bookingId: widget.bookingId,
          rating: _rating,
          comment: _commentController.text.trim(),
          isAnonymous: _isAnonymous,
          images: imageUrls,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Review' : 'Write a Review')),
      body: BlocListener<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewCreated || state is ReviewUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.isEdit ? 'Review updated!' : 'Review submitted! Awaiting moderation.')),
            );
            Navigator.pop(context, true);
          } else if (state is ReviewFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${state.error}'), backgroundColor: AppColors.error),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.shopName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('How was your experience?', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              Center(
                child: RatingBar(
                  rating: _rating,
                  size: 42,
                  showLabel: true,
                  onChanged: (val) => setState(() => _rating = val),
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: _rating >= 4 ? 'What went well?' : (_rating >= 3 ? 'How could we improve?' : 'What can we improve?'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surface,
                  counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),

              // Image section
              Row(
                children: [
                  const Icon(LucideIcons.image, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Add Photos', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('${_images.length}/5', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              if (_images.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => _buildImageThumb(index),
                  ),
                ),
              if (_images.length < 5) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _pickImage,
                ),
              ],
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Post anonymously', style: TextStyle(color: AppColors.textSecondary)),
                  const Spacer(),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              BlocBuilder<ReviewBloc, ReviewState>(
                builder: (context, state) {
                  final isSubmitting = state is ReviewLoading;
                  final canSubmit = _rating > 0;
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmit ? AppColors.primary : AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (isSubmitting || !canSubmit || _isUploading) ? null : _submit,
                    icon: isSubmitting || _isUploading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.star),
                    label: Text(
                      isSubmitting
                          ? 'Submitting...'
                          : _isUploading
                              ? 'Uploading images...'
                              : (widget.isEdit ? 'Update Review' : 'Submit Review'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumb(int index) {
    final item = _images[index];
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            color: AppColors.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: item.file.path.isNotEmpty
                ? Image.file(item.file, fit: BoxFit.cover, width: 100, height: 100)
                : (item.url != null
                    ? Image.network(item.url!, fit: BoxFit.cover, width: 100, height: 100)
                    : const SizedBox.shrink()),
          ),
        ),
        if (item.isUploading)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.4),
            ),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
          ),
        if (item.hasFailed)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 24),
                onPressed: () => _retryUpload(index),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}