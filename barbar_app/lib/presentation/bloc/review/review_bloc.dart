import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/review_model.dart';
import '../../../domain/repositories/review_repository.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository _reviewRepository;

  ReviewBloc(this._reviewRepository) : super(ReviewInitial()) {
    on<CreateReview>(_onCreateReview);
    on<UpdateReview>(_onUpdateReview);
    on<FetchPublicReviews>(_onFetchPublicReviews);
    on<FetchShopRatingSummary>(_onFetchShopRatingSummary);
    on<FetchMyReviews>(_onFetchMyReviews);
    on<ReplyToReview>(_onReplyToReview);
  }

  Future<void> _onCreateReview(CreateReview event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      final review = await _reviewRepository.createReview(
        bookingId: event.bookingId,
        staffId: event.staffId,
        shopRating: event.shopRating,
        staffRating: event.staffRating,
        comment: event.comment,
        isAnonymous: event.isAnonymous,
        images: event.images,
      );
      emit(ReviewCreated(review));
    } catch (e) {
      emit(ReviewFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchPublicReviews(FetchPublicReviews event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      final result = await _reviewRepository.getPublicReviews(event.shopId,
          page: event.page, limit: event.limit, sort: event.sort, staffId: event.staffId);
      final data = result['data'] as Map<String, dynamic>;
      final rawReviews = data['reviews'] as List;
      final summaryJson = data['summary'] as Map<String, dynamic>;
      final meta = result['meta'] as Map<String, dynamic>?;

      final reviews = rawReviews.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
      final summary = ReviewSummaryModel.fromJson(summaryJson);
      final total = (meta?['total'] as num?)?.toInt() ?? reviews.length;

      emit(PublicReviewsLoaded(
        reviews: reviews,
        summary: summary,
        page: event.page,
        total: total,
        hasMore: reviews.length >= event.limit,
      ));
    } catch (e) {
      emit(ReviewFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchShopRatingSummary(FetchShopRatingSummary event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      final result = await _reviewRepository.getShopRatingSummary(event.shopId);
      final summary = ReviewSummaryModel.fromJson(result);
      emit(ShopRatingSummaryLoaded(summary));
    } catch (e) {
      emit(ReviewFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateReview(UpdateReview event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      final review = await _reviewRepository.updateReview(
        reviewId: event.reviewId,
        shopRating: event.shopRating,
        staffRating: event.staffRating,
        comment: event.comment,
        isAnonymous: event.isAnonymous,
        images: event.images,
      );
      emit(ReviewUpdated(review));
    } catch (e) {
      emit(ReviewFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchMyReviews(FetchMyReviews event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      final reviews = await _reviewRepository.getMyReviews(page: event.page, limit: event.limit);
      emit(MyReviewsLoaded(reviews));
    } catch (e) {
      emit(ReviewFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onReplyToReview(ReplyToReview event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      await _reviewRepository.replyToReview(event.reviewId, event.reply);
      emit(ReviewSuccess('Reply posted'));
    } catch (e) {
      emit(ReviewFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
