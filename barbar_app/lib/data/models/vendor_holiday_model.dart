class VendorHolidayModel {
  final String id;
  final String branchId;
  final String date;
  final String title;
  final bool isFullDay;
  final String? startTime;
  final String? endTime;
  final String? reason;
  final String? createdAt;

  VendorHolidayModel({
    required this.id,
    required this.branchId,
    required this.date,
    required this.title,
    this.isFullDay = true,
    this.startTime,
    this.endTime,
    this.reason,
    this.createdAt,
  });

  factory VendorHolidayModel.fromJson(Map<String, dynamic> json) {
    return VendorHolidayModel(
      id: json['id'] ?? '',
      branchId: json['branch_id'] ?? '',
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      isFullDay: json['is_full_day'] as bool? ?? true,
      startTime: json['start_time'],
      endTime: json['end_time'],
      reason: json['reason'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'is_full_day': isFullDay,
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
    };
  }
}
