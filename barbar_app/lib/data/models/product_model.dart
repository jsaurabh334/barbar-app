import 'dart:io';
import 'package:flutter/foundation.dart';
import 'product_variant_model.dart';

class ProductModel {
  final String id;
  final String vendorId;
  final String? vendorName;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final String? shortDescription;
  final String? brandName;
  final String? brandId;
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
  final bool hasVariants;
  final List<ProductVariantModel>? variants;

  String? get brand => brandName;

  ProductModel({
    required this.id,
    required this.vendorId,
    this.vendorName,
    this.categoryId,
    this.categoryName,
    required this.name,
    required this.description,
    this.shortDescription,
    this.brandName,
    this.brandId,
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
    this.hasVariants = false,
    this.variants,
  });

  double get displayPrice => discountPrice ?? basePrice;
  bool get hasDiscount => discountPrice != null && discountPrice! < basePrice;
  bool get isLowStock => availableStock > 0 && availableStock <= lowStockThreshold;
  bool get outOfStock => availableStock <= 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? img;
    List<String>? allImages;
    final rawImages = json['images'] as List?;
    
    String fixUrl(String url) {
      if (!kIsWeb && Platform.isAndroid && url.contains('localhost')) {
        return url.replaceAll('localhost', '10.0.2.2');
      }
      return url;
    }

    if (rawImages != null && rawImages.isNotEmpty) {
      allImages = rawImages.map((e) {
        final u = (e is Map) ? (e['image_url'] as String?) ?? '' : e.toString();
        return u.isNotEmpty ? fixUrl(u) : u;
      }).where((u) => u.isNotEmpty).toList();
      img = allImages.isNotEmpty ? allImages.first : null;
    } else {
      final jsonImg = json['image_url'] as String?;
      img = jsonImg != null ? fixUrl(jsonImg) : null;
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
      vName = json['vendor']['business_name'] as String?;
    }

    List<ProductVariantModel>? variantsList;
    final rawVariants = json['variants'] as List?;
    if (rawVariants != null) {
      variantsList = rawVariants
          .map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
      brandName: json['brand_name'] as String? ?? json['brand'] as String?,
      brandId: json['brand_id'] as String?,
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
      hasVariants: json['has_variants'] as bool? ?? false,
      variants: variantsList,
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
      'brand_name': brandName,
      'brand_id': brandId,
      'has_variants': hasVariants,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'description': description,
      'short_description': shortDescription,
      'brand_name': brandName,
      'brand_id': brandId,
      'category_id': categoryId,
      'base_price': basePrice,
      'discount_price': discountPrice,
      'total_stock': totalStock,
      'available_stock': availableStock,
      'low_stock_threshold': lowStockThreshold,
      'has_variants': hasVariants,
      if (tags != null) 'tags': tags,
      if (variants != null) 'variants': variants!.map((v) => v.toJson()).toList(),
    };
  }
}
