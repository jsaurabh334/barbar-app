import 'package:equatable/equatable.dart';

class VendorBrandModel extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String? slug;
  final String? description;
  final String? logo;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VendorBrandModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.slug,
    this.description,
    this.logo,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory VendorBrandModel.fromJson(Map<String, dynamic> json) {
    return VendorBrandModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
      description: json['description'],
      logo: json['logo'],
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'logo': logo,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  VendorBrandModel copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? slug,
    String? description,
    String? logo,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorBrandModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, vendorId, name, slug, description, logo, isActive, sortOrder, createdAt, updatedAt];

  @override
  String toString() {
    return 'VendorBrandModel(id: $id, vendorId: $vendorId, name: $name, slug: $slug, '
        'description: $description, logo: $logo, isActive: $isActive, sortOrder: $sortOrder)';
  }
}
