class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final String? image;
  final String? link;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.image,
    this.link,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? val) {
      if (val == null || val.isEmpty) return null;
      return DateTime.tryParse(val);
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      data: json['data'] as Map<String, dynamic>?,
      image: json['image'] as String?,
      link: json['link'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: parseDate(json['read_at'] as String?),
      createdAt: parseDate(json['created_at'] as String?) ?? DateTime.now(),
    );
  }
}
