import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../models/review_model.dart';

class ReviewRemoteDataSource {
  final ApiClient _apiClient;

  ReviewRemoteDataSource(this._apiClient);

  Future<ReviewModel> createReview({
    required String bookingId,
    String? staffId,
    required int shopRating,
    int? staffRating,
    String comment = '',
    bool isAnonymous = false,
    List<Map<String, dynamic>> images = const [],
  }) async {
    final response = await _apiClient.dio.post(
      '/reviews',
      data: {
        'booking_id': bookingId,
        if (staffId != null) 'staff_id': staffId,
        'shop_rating': shopRating,
        if (staffRating != null) 'staff_rating': staffRating,
        'comment': comment,
        'is_anonymous': isAnonymous,
        if (images.isNotEmpty) 'images': images,
      },
    );
    if (response.statusCode == 201 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
      return ReviewModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data['error'] ?? 'Failed to create review');
  }

  Future<Map<String, dynamic>> getPublicReviews(
    String shopId, {
    int page = 1,
    int limit = 10,
    String sort = 'newest',
    String? staffId,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit, 'sort': sort};
    if (staffId != null) params['staff_id'] = staffId;
    final response = await _apiClient.dio.get(
      '/public/barbers/$shopId/reviews',
      queryParameters: params,
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch reviews');
  }

  Future<Map<String, dynamic>> getShopRatingSummary(String shopId) async {
    final response = await _apiClient.dio.get('/public/barbers/$shopId/rating-summary');
    if (response.statusCode == 200 && (response.data['status'] == 'success')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch rating summary');
  }

  Future<List<ReviewModel>> getMyReviews({int page = 1, int limit = 10}) async {
    final response = await _apiClient.dio.get('/reviews/mine', queryParameters: {'page': page, 'limit': limit});
    if (response.statusCode == 200 && (response.data['status'] == 'success')) {
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch my reviews');
  }

  Future<Map<String, dynamic>> uploadImage(File file, {void Function(int, int)? onProgress}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
    });
    final response = await _apiClient.dio.post(
      '/upload/image?dir=reviews',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      onSendProgress: onProgress,
    );
    if (response.statusCode == 201 && (response.data['status'] == 'created' || response.data['status'] == 'success')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception(response.data['error'] ?? 'Failed to upload image');
  }

  Future<ReviewModel> updateReview({
    required String reviewId,
    required int shopRating,
    int? staffRating,
    String comment = '',
    bool isAnonymous = false,
    List<Map<String, dynamic>> images = const [],
  }) async {
    final response = await _apiClient.dio.put(
      '/reviews/$reviewId',
      data: {
        'shop_rating': shopRating,
        if (staffRating != null) 'staff_rating': staffRating,
        'comment': comment,
        'is_anonymous': isAnonymous,
        if (images.isNotEmpty) 'images': images,
      },
    );
    if (response.statusCode == 200 && (response.data['status'] == 'success')) {
      return ReviewModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    throw Exception(response.data['error'] ?? 'Failed to update review');
  }

  Future<void> reportReview(String reviewId, String reason, {String? customReason}) async {
    final response = await _apiClient.dio.post(
      '/reviews/$reviewId/report',
      data: {
        'reason': reason,
        if (customReason != null && customReason.isNotEmpty) 'custom_reason': customReason,
      },
    );
    if (response.statusCode != 201) {
      throw Exception(response.data?['error'] ?? 'Failed to report review');
    }
  }

  Future<Map<String, dynamic>> getStaffProfile(String staffId) async {
    final response = await _apiClient.dio.get('/public/staff/$staffId');
    if (response.statusCode == 200 && (response.data['status'] == 'success')) {
      return response.data['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch staff profile');
  }

  Future<Map<String, dynamic>> getStaffReviews(String staffId, {int page = 1, int limit = 10}) async {
    final response = await _apiClient.dio.get(
      '/public/staff/$staffId/reviews',
      queryParameters: {'page': page, 'limit': limit},
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch staff reviews');
  }

  Future<void> replyToReview(String reviewId, String reply) async {
    final response = await _apiClient.dio.post(
      '/barber/reviews/$reviewId/reply',
      data: {'message': reply},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data?['error'] ?? 'Failed to reply to review');
    }
  }
}
