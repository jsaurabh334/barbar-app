class StatusHelper {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String suspended = 'suspended';
  static const String active = 'active';

  static String normalize(String? status) {
    if (status == null) return '';
    return status.trim().toLowerCase();
  }

  static bool isPending(String? status) => normalize(status) == pending;
  static bool isApproved(String? status) => normalize(status) == approved;
  static bool isRejected(String? status) => normalize(status) == rejected;
  static bool isSuspended(String? status) => normalize(status) == suspended;
  static bool isActive(String? status) => normalize(status) == active;
}
