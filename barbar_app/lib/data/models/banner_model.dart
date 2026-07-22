class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final String position;
  final bool isActive;
  final int sortOrder;
  final String? startDate;
  final String? endDate;
  final String createdAt;
  final String updatedAt;

  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.position,
    required this.isActive,
    required this.sortOrder,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      linkUrl: json['link_url'] as String?,
      position: json['position'] as String,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'image_url': imageUrl,
    if (linkUrl != null) 'link_url': linkUrl,
    'position': position,
    'sort_order': sortOrder,
    if (startDate != null) 'start_date': startDate,
    if (endDate != null) 'end_date': endDate,
  };
}
