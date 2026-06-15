import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Uri _url(String endpoint) => Uri.parse('${ApiConfig.baseUrl}/$endpoint');

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(_url(endpoint));
    return _process(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      _url(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return _process(response);
  }

  static dynamic _process(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Respuesta invalida del servidor: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
      return body['data'];
    }

    throw ApiException(body['message'] ?? 'Error desconocido');
  }
}
