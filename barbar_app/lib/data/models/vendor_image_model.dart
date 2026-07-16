class VendorImageModel {
  final String id;
  final String vendorId;
  final String? branchId;
  final String imageUrl;
  final String imageType;
  final int sortOrder;
  final String? caption;
  final bool isPrimary;
  final String? createdAt;

  VendorImageModel({
    required this.id,
    required this.vendorId,
    this.branchId,
    required this.imageUrl,
    this.imageType = 'gallery',
    this.sortOrder = 0,
    this.caption,
    this.isPrimary = false,
    this.createdAt,
  });

  factory VendorImageModel.fromJson(Map<String, dynamic> json) {
    return VendorImageModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      branchId: json['branch_id'],
      imageUrl: json['image_url'] ?? '',
      imageType: json['image_type'] ?? 'gallery',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      caption: json['caption'],
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'image_type': imageType,
      'branch_id': branchId,
      'sort_order': sortOrder,
      'caption': caption,
      'is_primary': isPrimary,
    };
  }
}
