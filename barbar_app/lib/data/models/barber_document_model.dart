class BarberDocumentModel {
  final String id;
  final String barberId;
  final String docType;
  final String docUrl;
  final String status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? remarks;

  BarberDocumentModel({
    required this.id,
    required this.barberId,
    required this.docType,
    required this.docUrl,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    this.remarks,
  });

  factory BarberDocumentModel.fromJson(Map<String, dynamic> json) {
    return BarberDocumentModel(
      id: json['id'] ?? '',
      barberId: json['barber_id'] ?? '',
      docType: json['doc_type'] ?? '',
      docUrl: json['doc_url'] ?? '',
      status: json['status'] ?? 'pending',
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at']) : null,
      remarks: json['remarks'],
    );
  }

  BarberDocumentModel copyWith({
    String? status,
    String? remarks,
  }) {
    return BarberDocumentModel(
      id: id,
      barberId: barberId,
      docType: docType,
      docUrl: docUrl,
      status: status ?? this.status,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      remarks: remarks ?? this.remarks,
    );
  }
}
