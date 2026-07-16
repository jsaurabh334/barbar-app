import 'dart:io';
import '../../data/models/review_model.dart';

abstract class ReviewRepository {
  Future<ReviewModel> createReview({
    required String bookingId,
    String? staffId,
    required int shopRating,
    int? staffRating,
    String comment = '',
    bool isAnonymous = false,
    List<Map<String, dynamic>> images = const [],
  });

  Future<Map<String, dynamic>> getPublicReviews(
    String shopId, {
    int page = 1,
    int limit = 10,
    String sort = 'newest',
    String? staffId,
  });

  Future<Map<String, dynamic>> getShopRatingSummary(String shopId);

  Future<List<ReviewModel>> getMyReviews({int page = 1, int limit = 10});

  Future<ReviewModel> updateReview({
    required String reviewId,
    required int shopRating,
    int? staffRating,
    String comment = '',
    bool isAnonymous = false,
    List<Map<String, dynamic>> images = const [],
  });

  Future<void> reportReview(String reviewId, String reason, {String? customReason});

  Future<void> replyToReview(String reviewId, String reply);

  Future<Map<String, dynamic>> uploadImage(File file, {void Function(int, int)? onProgress});

  Future<Map<String, dynamic>> getStaffProfile(String staffId);

  Future<Map<String, dynamic>> getStaffReviews(String staffId, {int page = 1, int limit = 10});
}
