import 'package:equatable/equatable.dart';

class ProductVariantModel extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String value;
  final String? sku;
  final String? barcode;
  final double price;
  final double? discountPrice;
  final int stock;
  final double? weight;
  final String? image;
  final bool isActive;
  final int? sortOrder;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    this.value = '',
    this.sku,
    this.barcode,
    required this.price,
    this.discountPrice,
    this.stock = 0,
    this.weight,
    this.image,
    this.isActive = true,
    this.sortOrder,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: json['discount_price'] != null ? (json['discount_price'] as num).toDouble() : null,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      image: json['image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'value': value,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'discount_price': discountPrice,
      'stock': stock,
      'weight': weight,
      'image': image,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [
    id, productId, name, value, sku, barcode, price, discountPrice,
    stock, weight, image, isActive, sortOrder,
  ];

  @override
  String toString() => 'ProductVariantModel(id: $id, name: $name, value: $value, price: $price)';
}
