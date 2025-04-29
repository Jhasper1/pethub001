import 'dart:convert';
import 'package:http/http.dart' as http;
import '/services/jwt_storage.dart'; // Import your TokenStorage class

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:5566'; // Change to your backend IP if needed

  // GET request with optional JWT auth
  Future<dynamic> getData(String endpoint, {bool requireAuth = false}) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // POST request with optional JWT auth and token parameter
  Future<dynamic> postData(String endpoint, Map<String, dynamic> data,
      {bool requireAuth = false, String? token}) async {
    final headers = await _buildHeaders(requireAuth: requireAuth, token: token);

    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  }

  // Build headers with JWT token if needed
  Future<Map<String, String>> _buildHeaders(
      {bool requireAuth = false, String? token}) async {
    final headers = {'Content-Type': 'application/json'};

    if (requireAuth || token != null) {
      final tokenToUse = token ?? await TokenStorage.getToken();

      if (tokenToUse != null && tokenToUse.isNotEmpty) {
        headers['Authorization'] = 'Bearer $tokenToUse';
      } else {
        throw Exception('No JWT token found');
      }
    }

    return headers;
  }
}