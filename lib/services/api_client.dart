import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../utils/endpoint_headers.dart';
import '../utils/keys.dart';
import '../providers/app_logic_provider.dart';

class APIClient {
  static APIClient? _instance;
  late Dio dio;

  APIClient._internal();

  factory APIClient() {
    _instance ??= APIClient._internal();
    return _instance!;
  }

  void init({ProviderContainer? container}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: Duration(seconds: 180),
        receiveTimeout: Duration(seconds: 180),
        sendTimeout: Duration(seconds: 180),
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
              String accessToken = appLogic.accessToken ?? "";
              options.headers.addAll({
                WAInterceptorHeaders.authorization: "Token $accessToken",
                WAInterceptorHeaders.xRequestWith: "XMLHttpRequest",
                WAInterceptorHeaders.contentType: "application/json",
              });
            } catch (e) {
              log("AccessToken Not Found Exception: $e");
              logoutAndRemoveData(container);
            }
          }
          return handler.next(options); //continue
        },
        onResponse: (response, handler) {
          /// Do something with response data
          if (response.data != null && response.data is Map) {
            final message = response.data["message"];
            if (message == "Token expired." || message == "Unauthorized") {
              ///Access token expire in this case logout user and redirect to login screen
              logoutAndRemoveData(container);
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
          return handler.next(e); //continue
        },
      ),
    );
  }

  void logoutAndRemoveData(ProviderContainer? container) {
    appLogic.clearDataAndRouteToHome(AppKeys.context!);
  }
}
