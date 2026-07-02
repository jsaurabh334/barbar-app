import 'package:dio/dio.dart';
import '../constants/constants.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';

class ApiClient {
  late final Dio dio;
  final AuthLocalDataSource _localDataSource;
  bool _isRefreshing = false;
  final List<void Function(String?)> _refreshQueue = [];

  ApiClient({AuthLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? AuthLocalDataSource() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _localDataSource.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (!options.path.startsWith('http') && options.path.startsWith('/')) {
            options.path = options.path.substring(1);
          }
          return handler.next(options);
        },
        onError: (err, handler) async {
          // If the status code is 401 or 419 (as unauthorized code specified in doc)
          if (err.response?.statusCode == 401 || err.response?.statusCode == 419) {
            final requestOptions = err.requestOptions;

            if (_isRefreshing) {
              // Queue the request until token refresh completes
              _refreshQueue.add((newToken) {
                if (newToken != null) {
                  requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  dio.fetch(requestOptions).then(
                    (response) => handler.resolve(response),
                    onError: (e) => handler.reject(e as DioException),
                  );
                } else {
                  handler.reject(err);
                }
              });
              return;
            }

            _isRefreshing = true;
            final refreshedToken = await _triggerTokenRefresh();
            _isRefreshing = false;

            if (refreshedToken != null) {
              // Retry the current failed request
              requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
              
              // Process queued requests
              for (final callback in _refreshQueue) {
                callback(refreshedToken);
              }
              _refreshQueue.clear();

              try {
                final response = await dio.fetch(requestOptions);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.reject(e);
              }
            } else {
              // Payout refresh failed - notify queue, clear session, and bubble error
              for (final callback in _refreshQueue) {
                callback(null);
              }
              _refreshQueue.clear();
              await _localDataSource.clearSession();
              return handler.reject(err);
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  Future<String?> _triggerTokenRefresh() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken == null) return null;

      // Use a clean, isolated Dio instance to avoid interceptor recursion loop
      final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await refreshDio.post(
        'auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == 'created')) {
        final tokens = response.data['data']['tokens'];
        final newAccessToken = tokens['access_token'] as String;
        final newRefreshToken = tokens['refresh_token'] as String;

        await _localDataSource.saveAccessToken(newAccessToken);
        await _localDataSource.saveRefreshToken(newRefreshToken);
        return newAccessToken;
      }
    } catch (_) {
      // Return null on failure
    }
    return null;
  }
}
