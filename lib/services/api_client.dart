import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../utils/endpoint_headers.dart';
import '../utils/keys.dart';
import '../providers/auth_provider.dart';

class APIClient {
  static APIClient? _instance;
  late Dio dio;
  ProviderContainer? _container;

  APIClient._internal();

  factory APIClient() {
    _instance ??= APIClient._internal();
    return _instance!;
  }

  void init({ProviderContainer? container}) {
    _container = container;

    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: Duration(minutes: 10),
        receiveTimeout: Duration(minutes: 10),
        sendTimeout: Duration(minutes: 10),
        validateStatus: (status) => true,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          /// Do something before request is sent
          if (options.headers.containsKey(WAInterceptorHeaders.requiresToken)) {
            options.headers.remove(WAInterceptorHeaders.requiresToken);
            try {
              String accessToken = appLogic.accessToken;
              if (accessToken.isEmpty) {
                log("AccessToken is empty - user not authenticated");
                _handleAuthError();
                return;
              }
              options.headers.addAll({
                WAInterceptorHeaders.authorization: "Token $accessToken",
                WAInterceptorHeaders.xRequestWith: "XMLHttpRequest",
                WAInterceptorHeaders.contentType: "application/json",
              });
            } catch (e) {
              log("AccessToken Not Found Exception: $e");
              _handleAuthError();
            }
          }
          return handler.next(options); //continue
        },
        onResponse: (response, handler) {
          /// Do something with response data
          if (response.data != null && response.data is Map) {
            var message = response.data["message"];
            var normalized = message.toLowerCase().trim();
            const errors = ["invalid token", "token expired", "unauthorized"];
            final hasError = errors.any((e) => normalized.contains(e));

            if (hasError) {
              ///Access token expired - logout user and redirect to login screen
              log('-------------- AUTH ERROR ---------------');
              log('Token expired or unauthorized - logging out user');
              _handleAuthError();
            }
          }
          return handler.next(response); // continue
        },
        onError: (DioException e, handler) {
          /// Do something with response error
          log('-------------- DIO ERROR ---------------');
          log('${e.response?.data.uri}   ${e.response?.data}');
          log(e.message ?? "");
          log('_RESPONSE');
          log(e.response.toString());

          // // Check for authentication errors (401 Unauthorized, 403 Forbidden)
          // if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          //   log(
          //     '-------------- AUTH ERROR (${e.response?.statusCode}) ---------------',
          //   );
          //   log('Unauthorized or Forbidden - logging out user');
          //   _handleAuthError();
          // }

          return handler.next(e); //continue
        },
      ),
    );
  }

  /// Handle authentication errors by logging out user and navigating to login
  void _handleAuthError() {
    try {
      // Use the auth provider to properly logout and clear all state
      if (_container != null) {
        _container!.read(authProvider.notifier).signOut();
      } else {
        // Fallback: just clear app logic data
        appLogic.accessToken = '';
        appLogic.user = null;
        appLogic.box.erase();
      }

      // Navigate to login screen
      final context = AppKeys.context;
      if (context != null && context.mounted) {
        // Use go_router to navigate to login
        context.go('/login');
      }
    } catch (e) {
      log('Error during auth error handling: $e');
    }
  }
}
