class CampaignModel {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String targetType;
  final String? scheduledAt;
  final String status;
  final int totalRecipients;
  final int sentCount;
  final int failedCount;
  final String createdAt;
  final String updatedAt;
  final String? sentAt;

  const CampaignModel({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.targetType,
    this.scheduledAt,
    required this.status,
    this.totalRecipients = 0,
    this.sentCount = 0,
    this.failedCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
  });

  String get targetLabel {
    switch (targetType) {
      case 'all': return 'All Users';
      case 'customers': return 'Customers';
      case 'vendors': return 'Vendors';
      case 'delivery': return 'Delivery Partners';
      case 'barbers': return 'Barbers';
      default: return targetType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'draft': return 'Draft';
      case 'scheduled': return 'Scheduled';
      case 'sending': return 'Sending...';
      case 'completed': return 'Completed';
      case 'failed': return 'Failed';
      default: return status;
    }
  }

  bool get isCompleted => status == 'completed' || status == 'failed';

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      imageUrl: json['image_url'] as String?,
      targetType: json['target_type'] as String,
      scheduledAt: json['scheduled_at'] as String?,
      status: json['status'] as String,
      totalRecipients: json['total_recipients'] as int? ?? 0,
      sentCount: json['sent_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      sentAt: json['sent_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    if (imageUrl != null) 'image_url': imageUrl,
    'target_type': targetType,
    if (scheduledAt != null) 'scheduled_at': scheduledAt,
  };
}
