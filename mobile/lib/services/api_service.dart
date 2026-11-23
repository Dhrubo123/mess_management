import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'auth_token';
  static String? _cachedToken;

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }

    String msg = 'Something went wrong (${response.statusCode})';
    if (body is Map<String, dynamic>) {
      if (body['message'] is String) {
        msg = body['message'];
      } else if (body['errors'] is Map) {
        final firstError = (body['errors'] as Map).values.first;
        if (firstError is List && firstError.isNotEmpty) {
          msg = firstError.first.toString();
        }
      }
    }
    throw ApiException(msg, response.statusCode);
  }

  static Future<Map<String, dynamic>> get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers());
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.post(uri, headers: await _headers(), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.patch(uri, headers: await _headers(), body: jsonEncode(data));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.delete(uri, headers: await _headers());
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, List<String>>? arrayFields,
    List<http.MultipartFile>? files,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    final token = await getToken();
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    if (arrayFields != null) {
      arrayFields.forEach((key, values) {
        for (var i = 0; i < values.length; i++) {
          request.fields['$key[$i]'] = values[i];
        }
      });
    }
    if (files != null) {
      request.files.addAll(files);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }
}
