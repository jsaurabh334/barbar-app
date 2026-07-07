class KycDocumentModel {
  final String id;
  final String userId;
  final String docType; // PAN, Aadhaar Front, Aadhaar Back, Shop License, GST, Selfie, Shop Photo
  final String docFrontUrl;
  final String? docBackUrl;
  final String status; // Pending, Under Review, Approved, Rejected, Expired
  final String? rejectReason;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  KycDocumentModel({
    required this.id,
    required this.userId,
    required this.docType,
    required this.docFrontUrl,
    this.docBackUrl,
    required this.status,
    this.rejectReason,
    this.verifiedBy,
    this.verifiedAt,
  });

  factory KycDocumentModel.fromJson(Map<String, dynamic> json) {
    return KycDocumentModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      docType: json['doc_type'] ?? '',
      docFrontUrl: json['doc_front_url'] ?? '',
      docBackUrl: json['doc_back_url'],
      status: json['status'] ?? 'pending',
      rejectReason: json['reject_reason'],
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'doc_type': docType,
      'doc_front_url': docFrontUrl,
      'doc_back_url': docBackUrl,
      'status': status,
      'reject_reason': rejectReason,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  KycDocumentModel copyWith({
    String? status,
    String? rejectReason,
  }) {
    return KycDocumentModel(
      id: id,
      userId: userId,
      docType: docType,
      docFrontUrl: docFrontUrl,
      docBackUrl: docBackUrl,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
    );
  }
}
