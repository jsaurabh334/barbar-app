class WarehouseModel {
  final String id;
  final String vendorId;
  final String name;
  final String? phone;
  final String? email;
  final String address;
  final String city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String warehouseType;
  final String status;
  final bool isDefault;
  final bool isActive;
  final int displayOrder;
  final String? createdAt;

  WarehouseModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.phone,
    this.email,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.warehouseType = 'both',
    this.status = 'active',
    this.isDefault = false,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'],
      pincode: json['pincode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      warehouseType: json['warehouse_type'] ?? 'both',
      status: json['status'] ?? 'active',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'warehouse_type': warehouseType,
      'is_default': isDefault,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}
