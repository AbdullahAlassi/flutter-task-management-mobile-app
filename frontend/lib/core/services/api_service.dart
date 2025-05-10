import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://localhost:3001'; // Backend server port

  Future<http.Response> get(String endpoint,
      {Map<String, String>? queryParams, Map<String, String>? headers}) async {
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    print('ApiService: Requesting $uri with headers: $headers');
    return await http.get(uri, headers: headers);
  }

  Future<http.Response> post(String endpoint,
      {required Map<String, dynamic> body,
      Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('ApiService: Requesting $uri with headers: $headers');
    return await http.post(
      uri,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<http.Response> put(String endpoint,
      {required Map<String, dynamic> body,
      Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('ApiService: Requesting $uri with headers: $headers');
    return await http.put(
      uri,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<http.Response> delete(String endpoint,
      {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('ApiService: Requesting $uri with headers: $headers');
    return await http.delete(uri, headers: headers);
  }
}
