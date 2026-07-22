class CmsPageModel {
  final String id;
  final String key;
  final String title;
  final String content;
  final String type;
  final int sortOrder;
  final bool isPublished;
  final String createdAt;
  final String updatedAt;

  const CmsPageModel({
    required this.id,
    required this.key,
    required this.title,
    required this.content,
    required this.type,
    this.sortOrder = 0,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeLabel => type == 'faq' ? 'FAQ' : 'Page';

  factory CmsPageModel.fromJson(Map<String, dynamic> json) {
    return CmsPageModel(
      id: json['id'] as String,
      key: json['key'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'content': content,
    'type': type,
    'sort_order': sortOrder,
    'is_published': isPublished,
  };
}
