import 'package:barbar_app/data/datasources/local/auth_local_datasource.dart';

class FakeAuthLocalDataSource extends AuthLocalDataSource {
  String? _token;

  FakeAuthLocalDataSource({String? token}) : _token = token;

  void setToken(String? token) => _token = token;

  @override
  Future<String?> getAccessToken() async => _token;

  @override
  Future<void> saveAccessToken(String token) async => _token = token;

  @override
  Future<void> deleteTokens() async => _token = null;
}
