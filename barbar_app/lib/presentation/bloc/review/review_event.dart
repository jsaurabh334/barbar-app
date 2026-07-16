import 'package:equatable/equatable.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class CreateReview extends ReviewEvent {
  final String bookingId;
  final String? staffId;
  final int shopRating;
  final int? staffRating;
  final String comment;
  final bool isAnonymous;
  final List<Map<String, dynamic>> images;

  const CreateReview({
    required this.bookingId,
    this.staffId,
    required this.shopRating,
    this.staffRating,
    this.comment = '',
    this.isAnonymous = false,
    this.images = const [],
  });

  @override
  List<Object?> get props => [bookingId, staffId, shopRating, staffRating, comment, isAnonymous, images];
}

class FetchPublicReviews extends ReviewEvent {
  final String shopId;
  final int page;
  final int limit;
  final String sort;
  final String? staffId;

  const FetchPublicReviews({
    required this.shopId,
    this.page = 1,
    this.limit = 10,
    this.sort = 'newest',
    this.staffId,
  });

  @override
  List<Object?> get props => [shopId, page, limit, sort, staffId];
}

class FetchShopRatingSummary extends ReviewEvent {
  final String shopId;

  const FetchShopRatingSummary(this.shopId);

  @override
  List<Object?> get props => [shopId];
}

class FetchMyReviews extends ReviewEvent {
  final int page;
  final int limit;

  const FetchMyReviews({this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [page, limit];
}

class ReplyToReview extends ReviewEvent {
  final String reviewId;
  final String reply;

  const ReplyToReview({required this.reviewId, required this.reply});

  @override
  List<Object?> get props => [reviewId, reply];
}

class UpdateReview extends ReviewEvent {
  final String reviewId;
  final int shopRating;
  final int? staffRating;
  final String comment;
  final bool isAnonymous;
  final List<Map<String, dynamic>> images;

  const UpdateReview({
    required this.reviewId,
    required this.shopRating,
    this.staffRating,
    this.comment = '',
    this.isAnonymous = false,
    this.images = const [],
  });

  @override
  List<Object?> get props => [reviewId, shopRating, staffRating, comment, isAnonymous, images];
}
