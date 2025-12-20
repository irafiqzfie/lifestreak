import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const _defaultBaseUrl = 'https://api.lifestreak.app';

  final Uri baseUrl;
  final http.Client _httpClient;

  ApiClient({Uri? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? Uri.parse(_defaultBaseUrl),
      _httpClient = httpClient ?? http.Client();

  Future<String> requestMagicLink(String email) async {
    final body = await _postJson('/auth/magic-link/request', {'email': email});
    return body['requestId'] as String? ?? '';
  }

  Future<Session> verifyMagicLink(String requestId, String code) async {
    final body = await _postJson('/auth/magic-link/verify', {
      'requestId': requestId,
      'code': code,
    });
    return Session.fromJson(body);
  }

  Future<void> syncHabitMetadata(
    List<Map<String, dynamic>> habits, {
    required String token,
  }) async {
    if (habits.isEmpty) return;
    await _postJson('/sync/habits', {'habits': habits}, token: token);
  }

  Future<void> syncLogs(
    List<Map<String, dynamic>> logs, {
    required String token,
  }) async {
    if (logs.isEmpty) return;
    await _postJson('/sync/logs', {'logs': logs}, token: token);
  }

  Future<List<Map<String, dynamic>>> fetchLogs({
    required String token,
    DateTime? since,
  }) async {
    final queryParameters = <String, String>{
      if (since != null) 'since': since.toIso8601String(),
    };
    final response = await _get(
      '/sync/logs',
      token: token,
      queryParameters: queryParameters,
    );
    final data = response['logs'];
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchFriendSummaries({
    required String token,
  }) async {
    final response = await _get('/friends/summaries', token: token);
    final data = response['friends'];
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  Future<void> sendFriendRequest(String email, {required String token}) async {
    await _postJson('/friends/request', {'email': email}, token: token);
  }

  Future<void> acceptFriendRequest(
    String userId, {
    required String token,
  }) async {
    await _postJson('/friends/accept', {'userId': userId}, token: token);
  }

  Future<void> rejectFriendRequest(
    String userId, {
    required String token,
  }) async {
    await _postJson('/friends/reject', {'userId': userId}, token: token);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = baseUrl.resolve(path);
    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    final base = baseUrl.resolve(path);
    final uri = queryParameters == null || queryParameters.isEmpty
        ? base
        : base.replace(queryParameters: queryParameters);
    final response = await _httpClient.get(uri, headers: _buildHeaders(token));
    return _processResponse(response);
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{'content-type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.body.isNotEmpty
            ? response.body
            : 'Unexpected ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    if (response.body.isEmpty) {
      return {};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
