class VendorWorkingHourModel {
  final String id;
  final String branchId;
  final int dayOfWeek;
  final String openTime;
  final String closeTime;
  final String? breakStart;
  final String? breakEnd;
  final bool isClosed;
  final String? createdAt;

  VendorWorkingHourModel({
    required this.id,
    required this.branchId,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    this.breakStart,
    this.breakEnd,
    this.isClosed = false,
    this.createdAt,
  });

  factory VendorWorkingHourModel.fromJson(Map<String, dynamic> json) {
    return VendorWorkingHourModel(
      id: json['id'] ?? '',
      branchId: json['branch_id'] ?? '',
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      openTime: json['open_time'] ?? '09:00',
      closeTime: json['close_time'] ?? '21:00',
      breakStart: json['break_start'],
      breakEnd: json['break_end'],
      isClosed: json['is_closed'] as bool? ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'open_time': openTime,
      'close_time': closeTime,
      'break_start': breakStart,
      'break_end': breakEnd,
      'is_closed': isClosed,
    };
  }

  String get dayName {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek.clamp(0, 6)];
  }

  String get fullDayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek.clamp(0, 6)];
  }
}
