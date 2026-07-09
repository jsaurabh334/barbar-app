import 'dart:io';
import '../../domain/repositories/review_repository.dart';
import '../datasources/remote/review_remote_datasource.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _remoteDataSource;

  ReviewRepositoryImpl(this._remoteDataSource);

  @override
  Future<ReviewModel> createReview({
    required String bookingId,
    required int rating,
    String comment = '',
    bool isAnonymous = false,
    List<Map<String, dynamic>> images = const [],
  }) async {
    return _remoteDataSource.createReview(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
      isAnonymous: isAnonymous,
      images: images,
    );
  }

  @override
  Future<Map<String, dynamic>> getPublicReviews(
    String shopId, {
    int page = 1,
    int limit = 10,
    String sort = 'newest',
  }) async {
    return _remoteDataSource.getPublicReviews(shopId, page: page, limit: limit, sort: sort);
  }

  @override
  Future<Map<String, dynamic>> getShopRatingSummary(String shopId) async {
    return _remoteDataSource.getShopRatingSummary(shopId);
  }

  @override
  Future<List<ReviewModel>> getMyReviews({int page = 1, int limit = 10}) async {
    return _remoteDataSource.getMyReviews(page: page, limit: limit);
  }

  @override
  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    String comment = '',
    bool isAnonymous = false,
    List<Map<String, dynamic>> images = const [],
  }) async {
    return _remoteDataSource.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
      isAnonymous: isAnonymous,
      images: images,
    );
  }

  @override
  Future<void> reportReview(String reviewId, String reason) async {
    return _remoteDataSource.reportReview(reviewId, reason);
  }

  @override
  Future<Map<String, dynamic>> uploadImage(File file, {void Function(int, int)? onProgress}) async {
    return _remoteDataSource.uploadImage(file, onProgress: onProgress);
  }
}
