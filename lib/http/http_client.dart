import 'dart:async';
import 'dart:convert';

import 'package:baselib/baselib.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get_connect/http/src/status/http_status.dart';

import '../lib_config.dart';
import 'model/response.dart';

typedef RequestFunc = Future<dio.Response> Function();

typedef AcceptFunc<T> = Future<AppResponse<T>> Function(RequestFunc requestFunc, {T? Function(dynamic data)? dataDecoder});

class HttpClientConfig {
  final String httpBaseUrl;

  final List<dio.Interceptor> httpInterceptors;

  final AcceptFunc acceptFunc;

  final int httpSuccessCode;

  HttpClientConfig.init({required this.httpBaseUrl, required this.httpInterceptors, required this.acceptFunc, this.httpSuccessCode = 200});
}

class DioClient {
  static final utf8decoder = Utf8Decoder();

  final dio.Dio _dio;

  final HttpClientConfig _config;

  DioClient({HttpClientConfig? config})
      : _dio = dio.Dio(),
        this._config = config ?? LibConfig.delegate.clientConfig {
    _dio.options
      ..baseUrl = this._config.httpBaseUrl
      ..connectTimeout = 30000
      ..receiveTimeout = 10000
      ..sendTimeout = 10000;
    _dio.interceptors.addAll(_config.httpInterceptors);
  }

  void clearHttpTask() {
    _dio.clear();
  }

  Future<String?> getString(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio.Options? options,
    dio.CancelToken? cancelToken,
    dio.ProgressCallback? onReceiveProgress,
  }) async {
    var response = await _dio.get(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
    if (response.statusCode == HttpStatus.ok) {
      return response.data.toString();
    }
    return null;
  }

  Future<AppResponse<T?>> postAccept<T>(String url,
      {dynamic body,
      T? Function(dynamic data)? dataDecoder,
      Map<String, dynamic>? queryParameters,
      dio.Options? options,
      dio.CancelToken? cancelToken,
      dio.ProgressCallback? onSendProgress,
      dio.ProgressCallback? onReceiveProgress}) async {
    return _config.acceptFunc.call(
        () => _dio.post(url,
            data: body,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onReceiveProgress,
            onReceiveProgress: onReceiveProgress),
        dataDecoder: dataDecoder) as Future<AppResponse<T?>>;
  }
}
