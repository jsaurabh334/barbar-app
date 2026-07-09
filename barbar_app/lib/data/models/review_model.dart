class ReviewImageModel {
  final String id;
  final String url;
  final String? thumbnail;
  final int sortOrder;
  final int size;

  ReviewImageModel({
    required this.id,
    required this.url,
    this.thumbnail,
    this.sortOrder = 0,
    this.size = 0,
  });

  factory ReviewImageModel.fromJson(Map<String, dynamic> json) {
    return ReviewImageModel(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnail: json['thumbnail'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'sort_order': sortOrder,
      'size': size,
    };
  }
}

class ReviewModel {
  final String id;
  final String bookingId;
  final String shopId;
  final String? staffId;
  final int rating;
  final String comment;
  final bool isAnonymous;
  final bool isVerified;
  final String status;
  final String createdAt;
  final List<ReviewImageModel> images;
  final String? customerName;
  final ReviewReplyModel? reply;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.shopId,
    this.staffId,
    required this.rating,
    this.comment = '',
    this.isAnonymous = false,
    this.isVerified = true,
    required this.status,
    required this.createdAt,
    this.images = const [],
    this.customerName,
    this.reply,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'] as List?;
    List<ReviewImageModel> imageList = rawImages != null
        ? rawImages.map((e) => ReviewImageModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    String? name;
    if (json['customer'] != null && json['customer']['full_name'] != null) {
      name = json['customer']['full_name'] as String;
    }

    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      shopId: json['shop_id'] as String,
      staffId: json['staff_id'] as String?,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String? ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? true,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      images: imageList,
      customerName: name,
      reply: json['reply'] != null
          ? ReviewReplyModel.fromJson(json['reply'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'shop_id': shopId,
      if (staffId != null) 'staff_id': staffId,
      'rating': rating,
      'comment': comment,
      'is_anonymous': isAnonymous,
      'is_verified': isVerified,
      'status': status,
      'created_at': createdAt,
      'images': images.map((e) => e.toJson()).toList(),
      if (reply != null) 'reply': reply!.toJson(),
    };
  }
}

class ReviewReplyModel {
  final String id;
  final String message;
  final String createdAt;

  ReviewReplyModel({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  factory ReviewReplyModel.fromJson(Map<String, dynamic> json) {
    return ReviewReplyModel(
      id: json['id'] as String,
      message: json['message'] as String,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'created_at': createdAt,
    };
  }
}

class ReviewSummaryModel {
  final double avgRating;
  final int totalReviews;
  final RatingDistribution distribution;

  ReviewSummaryModel({
    this.avgRating = 0.0,
    this.totalReviews = 0,
    this.distribution = const RatingDistribution(),
  });

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReviewSummaryModel(
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      distribution: json['rating_distribution'] != null
          ? RatingDistribution.fromJson(json['rating_distribution'] as Map<String, dynamic>)
          : const RatingDistribution(),
    );
  }
}

class RatingDistribution {
  final int star5;
  final int star4;
  final int star3;
  final int star2;
  final int star1;

  const RatingDistribution({
    this.star5 = 0,
    this.star4 = 0,
    this.star3 = 0,
    this.star2 = 0,
    this.star1 = 0,
  });

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    return RatingDistribution(
      star5: (json['5'] as num?)?.toInt() ?? 0,
      star4: (json['4'] as num?)?.toInt() ?? 0,
      star3: (json['3'] as num?)?.toInt() ?? 0,
      star2: (json['2'] as num?)?.toInt() ?? 0,
      star1: (json['1'] as num?)?.toInt() ?? 0,
    );
  }
}
