import 'package:equatable/equatable.dart';
import '../../../data/models/review_model.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewCreated extends ReviewState {
  final ReviewModel review;

  const ReviewCreated(this.review);

  @override
  List<Object?> get props => [review];
}

class PublicReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final ReviewSummaryModel summary;
  final int page;
  final int total;
  final bool hasMore;

  const PublicReviewsLoaded({
    required this.reviews,
    required this.summary,
    this.page = 1,
    this.total = 0,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [reviews, summary, page, total, hasMore];
}

class ShopRatingSummaryLoaded extends ReviewState {
  final ReviewSummaryModel summary;

  const ShopRatingSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class MyReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;

  const MyReviewsLoaded(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class ReviewUpdated extends ReviewState {
  final ReviewModel review;

  const ReviewUpdated(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewFailure extends ReviewState {
  final String error;

  const ReviewFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class ReviewSuccess extends ReviewState {
  final String message;

  const ReviewSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
