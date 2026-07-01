import 'package:dio/dio.dart';

import '../../core/constants.dart';

class ApiClient {
  ApiClient({double timeout = AppConstants.networkTimeout})
      : _dio = Dio(BaseOptions(
          connectTimeout: Duration(milliseconds: (timeout * 1000).round()),
          receiveTimeout: Duration(milliseconds: (timeout * 1000).round()),
          headers: {'User-Agent': AppConstants.userAgent},
        ));

  final Dio _dio;

  Future<String> getText(String url, {Map<String, String>? headers}) async {
    final resp = await _dio.get<String>(
      url,
      options: Options(headers: headers, responseType: ResponseType.plain),
    );
    return resp.data ?? '';
  }

  Future<List<int>> getBytes(String url, {Map<String, String>? headers}) async {
    final resp = await _dio.get<List<int>>(
      url,
      options: Options(headers: headers, responseType: ResponseType.bytes),
    );
    return resp.data ?? [];
  }

  Future<Map<String, dynamic>> getJson(String url, {Map<String, String>? headers}) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      url,
      options: Options(headers: headers, responseType: ResponseType.json),
    );
    return resp.data ?? {};
  }

  Future<List<dynamic>> getJsonList(String url, {Map<String, String>? headers}) async {
    final resp = await _dio.get<dynamic>(
      url,
      options: Options(headers: headers, responseType: ResponseType.json),
    );
    final data = resp.data;
    if (data is List) return data;
    return [];
  }
}
