import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Base URL for the Node.js/Express backend.
///
/// Uses localhost because `adb reverse tcp:3000 tcp:3000` tunnels the
/// emulator's localhost:3000 directly to the host machine's port 3000.
///
/// Run this once whenever you start a new emulator session:
///   %LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe reverse tcp:3000 tcp:3000
///
/// For a physical device: replace with your machine's LAN IP, e.g.:
///   http://192.168.29.56:3000/api
const String _kBaseUrl = 'http://localhost:3000/api';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Central HTTP client for all backend REST calls.
/// Automatically attaches the current Firebase ID token as `Authorization: Bearer <token>`.
class ApiService {
  ApiService._();

  static Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.getIdToken();
  }

  static Future<Map<String, String>> _buildHeaders() async {
    final token = await _getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path) => Uri.parse('$_kBaseUrl$path');

  static dynamic _parseResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    final decoded = jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = (decoded is Map && decoded['error'] != null)
        ? decoded['error'].toString()
        : 'Request failed with status ${response.statusCode}';

    throw ApiException(response.statusCode, message);
  }

  /// HTTP GET
  static Future<dynamic> get(String path) async {
    final headers = await _buildHeaders();
    final response = await http.get(_uri(path), headers: headers);
    return _parseResponse(response);
  }

  /// HTTP POST
  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final headers = await _buildHeaders();
    final response = await http.post(
      _uri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _parseResponse(response);
  }

  /// HTTP PATCH
  static Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final headers = await _buildHeaders();
    final response = await http.patch(
      _uri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _parseResponse(response);
  }

  /// HTTP DELETE
  static Future<dynamic> delete(String path) async {
    final headers = await _buildHeaders();
    final response = await http.delete(_uri(path), headers: headers);
    return _parseResponse(response);
  }

  /// Multipart POST for uploading files (e.g. camera images).
  static Future<dynamic> postMultipart(
    String path, {
    required Uint8List imageBytes,
    required String mimeType,
    String? caption,
  }) async {
    final token = await _getIdToken();
    final request = http.MultipartRequest('POST', _uri(path));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final mimeParts = mimeType.split('/');
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'capture.jpg',
      contentType: MediaType(mimeParts[0], mimeParts.length > 1 ? mimeParts[1] : 'jpeg'),
    ));

    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

}
