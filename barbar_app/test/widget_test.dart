import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/data/models/user_model.dart';
import 'package:barbar_app/data/models/product_model.dart';
import 'package:barbar_app/data/models/category_model.dart';
import 'package:barbar_app/data/models/order_model.dart';

void main() {
  group('UserModel Serialization', () {
    test('should parse user model from valid JSON', () {
      final json = {
        'id': '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
        'email': 'johndoe@example.com',
        'phone': '+919999999999',
        'full_name': 'John Doe',
        'avatar': 'http://localhost/avatar.png',
        'role': 'customer',
        'status': 'active',
        'otp_verified': true,
        'language_pref': 'en',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d');
      expect(model.email, 'johndoe@example.com');
      expect(model.phone, '+919999999999');
      expect(model.fullName, 'John Doe');
      expect(model.role, 'customer');
      expect(model.otpVerified, true);
    });

    test('should output valid JSON map', () {
      final model = UserModel(
        id: '123',
        phone: '+919999999999',
        fullName: 'Jane Doe',
        role: 'barber',
        status: 'active',
        otpVerified: false,
        languagePref: 'hi',
      );

      final json = model.toJson();

      expect(json['id'], '123');
      expect(json['phone'], '+919999999999');
      expect(json['full_name'], 'Jane Doe');
      expect(json['role'], 'barber');
      expect(json['otp_verified'], false);
      expect(json['language_pref'], 'hi');
    });
  });

  group('ProductModel Serialization', () {
    test('should parse product model from minimal JSON', () {
      final json = {
        'id': 'prod-1',
        'vendor_id': 'vendor-1',
        'name': 'Test Product',
        'description': 'A test product',
        'base_price': 100,
      };

      final model = ProductModel.fromJson(json);

      expect(model.id, 'prod-1');
      expect(model.vendorId, 'vendor-1');
      expect(model.name, 'Test Product');
      expect(model.basePrice, 100);
      expect(model.availableStock, 0);
      expect(model.rating, 0);
      expect(model.vendorName, isNull);
      expect(model.categoryName, isNull);
    });

    test('should parse product model with nested vendor and category', () {
      final json = {
        'id': 'prod-2',
        'vendor_id': 'vendor-2',
        'vendor': {'business_name': 'Best Store'},
        'category_id': 'cat-1',
        'category': {'name': 'Grooming'},
        'name': 'Premium Oil',
        'description': 'Hair oil',
        'base_price': 299,
        'discount_price': 199,
        'total_stock': 100,
        'available_stock': 85,
        'low_stock_threshold': 10,
        'sold_count': 15,
        'rating': 4.5,
        'review_count': 10,
        'is_approved': true,
        'is_active': true,
        'images': [{'image_url': 'http://example.com/img1.jpg'}],
        'tags': ['organic', 'herbal'],
      };

      final model = ProductModel.fromJson(json);

      expect(model.vendorName, 'Best Store');
      expect(model.categoryId, 'cat-1');
      expect(model.categoryName, 'Grooming');
      expect(model.discountPrice, 199);
      expect(model.displayPrice, 199);
      expect(model.hasDiscount, isTrue);
      expect(model.totalStock, 100);
      expect(model.availableStock, 85);
      expect(model.imageUrl, 'http://example.com/img1.jpg');
      expect(model.tags, ['organic', 'herbal']);
      expect(model.isLowStock, isFalse);
      expect(model.outOfStock, isFalse);
    });

    test('toJson should output expected fields', () {
      final model = ProductModel(
        id: 'p1',
        vendorId: 'v1',
        name: 'Oil',
        description: 'Good oil',
        basePrice: 199,
        availableStock: 50,
        isApproved: true,
      );

      final json = model.toJson();

      expect(json['id'], 'p1');
      expect(json['name'], 'Oil');
      expect(json['base_price'], 199);
    });

    test('toCreateJson should output product creation fields', () {
      final model = ProductModel(
        id: 'p1',
        vendorId: 'v1',
        name: 'Oil',
        description: 'Good oil',
        basePrice: 199,
        discountPrice: 149,
        totalStock: 100,
        availableStock: 100,
        lowStockThreshold: 10,
        categoryId: 'cat-1',
        tags: ['organic'],
      );

      final json = model.toCreateJson();

      expect(json['name'], 'Oil');
      expect(json['base_price'], 199);
      expect(json['discount_price'], 149);
      expect(json['total_stock'], 100);
      expect(json['category_id'], 'cat-1');
      expect(json['tags'], ['organic']);
    });
  });

  group('CategoryModel Serialization', () {
    test('should parse category model from JSON', () {
      final json = {
        'id': 'cat-1',
        'name': 'Grooming',
        'slug': 'grooming',
        'description': 'Grooming products',
      };

      final model = CategoryModel.fromJson(json);

      expect(model.id, 'cat-1');
      expect(model.name, 'Grooming');
      expect(model.slug, 'grooming');
    });
  });

  group('OrderModel Serialization', () {
    test('should parse order model from JSON', () {
      final json = {
        'id': 'order-1',
        'order_number': 'ORD-001',
        'status': 'pending',
        'items_total': 500,
        'shipping_charge': 50,
        'tax_amount': 40,
        'discount_amount': 0,
        'final_amount': 590,
        'payment_status': 'pending',
      };

      final model = OrderModel.fromJson(json);

      expect(model.id, 'order-1');
      expect(model.orderNumber, 'ORD-001');
      expect(model.status, 'pending');
      expect(model.finalAmount, 590);
      expect(model.paymentStatus, 'pending');
    });
  });
}
