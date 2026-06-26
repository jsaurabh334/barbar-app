import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/data/models/user_model.dart';

void main() {
  group('UserModel Serialization Tests', () {
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
}
