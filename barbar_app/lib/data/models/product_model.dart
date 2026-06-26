class ProductModel {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double basePrice;
  final double? discountPrice;
  final int availableStock;
  final bool isApproved;
  final String? imageUrl;

  ProductModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.basePrice,
    this.discountPrice,
    required this.availableStock,
    required this.isApproved,
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? img;
    var rawImages = json['images'] as List?;
    if (rawImages != null && rawImages.isNotEmpty) {
      img = rawImages.first['image_url'] as String?;
    } else {
      img = json['image_url'] as String?;
    }

    return ProductModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      basePrice: (json['base_price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null ? (json['discount_price'] as num).toDouble() : null,
      availableStock: (json['available_stock'] as num?)?.toInt() ?? (json['total_stock'] as num?)?.toInt() ?? 0,
      isApproved: json['is_approved'] as bool? ?? false,
      imageUrl: img,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'discount_price': discountPrice,
      'available_stock': availableStock,
      'is_approved': isApproved,
      'image_url': imageUrl,
    };
  }
}
