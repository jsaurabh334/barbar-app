class ProductModel {
  final String id;
  final String vendorId;
  final String? vendorName;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final String? shortDescription;
  final String? brand;
  final double basePrice;
  final double? discountPrice;
  final int totalStock;
  final int availableStock;
  final int lowStockThreshold;
  final int soldCount;
  final double rating;
  final int reviewCount;
  final bool isApproved;
  final bool isActive;
  final String? imageUrl;
  final List<String>? images;
  final List<String>? tags;

  ProductModel({
    required this.id,
    required this.vendorId,
    this.vendorName,
    this.categoryId,
    this.categoryName,
    required this.name,
    required this.description,
    this.shortDescription,
    this.brand,
    required this.basePrice,
    this.discountPrice,
    this.totalStock = 0,
    this.availableStock = 0,
    this.lowStockThreshold = 10,
    this.soldCount = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.isApproved = false,
    this.isActive = true,
    this.imageUrl,
    this.images,
    this.tags,
  });

  double get displayPrice => discountPrice ?? basePrice;
  bool get hasDiscount => discountPrice != null && discountPrice! < basePrice;
  bool get isLowStock => availableStock > 0 && availableStock <= lowStockThreshold;
  bool get outOfStock => availableStock <= 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? img;
    List<String>? allImages;
    final rawImages = json['images'] as List?;
    if (rawImages != null && rawImages.isNotEmpty) {
      allImages = rawImages.map((e) => (e is Map) ? (e['image_url'] as String?) ?? '' : e.toString()).where((u) => u.isNotEmpty).toList();
      img = allImages.isNotEmpty ? allImages.first : null;
    } else {
      img = json['image_url'] as String?;
    }

    List<String>? tagsList;
    final rawTags = json['tags'];
    if (rawTags is List) {
      tagsList = rawTags.map((e) => e.toString()).toList();
    }

    String? catName;
    if (json['category'] is Map) {
      catName = json['category']['name'] as String?;
    }

    String? vName;
    if (json['vendor'] is Map) {
      vName = json['vendor']['store_name'] as String?;
    }

    return ProductModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      vendorName: vName,
      categoryId: json['category_id'] as String?,
      categoryName: catName,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      shortDescription: json['short_description'] as String?,
      brand: json['brand'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null ? (json['discount_price'] as num).toDouble() : null,
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 0,
      availableStock: (json['available_stock'] as num?)?.toInt() ?? (json['total_stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 10,
      soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: img,
      images: allImages,
      tags: tagsList,
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

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'description': description,
      'short_description': shortDescription,
      'brand': brand,
      'category_id': categoryId,
      'base_price': basePrice,
      'discount_price': discountPrice,
      'total_stock': totalStock,
      'available_stock': availableStock,
      'low_stock_threshold': lowStockThreshold,
      if (tags != null) 'tags': tags,
    };
  }
}
