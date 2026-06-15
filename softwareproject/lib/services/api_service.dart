import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL base de la API PHP en XAMPP
  static const String baseUrl = 'http://127.0.0.1/sportmanager_api';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
  };

  // GET
  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    return _handleResponse(res);
  }

  // POST
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _handleResponse(res);
  }

  // PUT
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.put(uri, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _handleResponse(res);
  }

  // DELETE
  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    final res = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 10));
    return _handleResponse(res);
  }

  static dynamic _handleResponse(http.Response res) {
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    } else {
      final msg = decoded['error'] ?? 'Error desconocido (${res.statusCode})';
      throw ApiException(msg, res.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
