import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_http_client.dart';

class CloudApiException implements Exception {
  const CloudApiException(this.code, this.statusCode);
  final String code;
  final int statusCode;
  @override
  String toString() => code;
}

class CloudApi {
  CloudApi(this.prefs) {
    _client = createCloudHttpClient();
    if (!kIsWeb) _sessionToken = prefs.getString('cloud_session_token');
  }

  final SharedPreferences prefs;
  late final http.Client _client;
  String? _sessionToken;
  bool isSignedIn = false;
  Map<String, dynamic>? currentUser;

  String get baseUrl {
    if (kIsWeb) return Uri.base.origin;
    return const String.fromEnvironment(
      'SA_AGRIAI_API_URL',
      defaultValue: 'https://sa-agriai-app.salahbenyahia687.workers.dev',
    );
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'accept': 'application/json'};
    if (!kIsWeb) {
      headers['x-sa-client'] = 'desktop';
      if (_sessionToken != null && _sessionToken!.isNotEmpty) {
        headers['authorization'] = 'Bearer $_sessionToken';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(baseUrl + path);
    final request = http.Request(method, uri);
    request.headers.addAll(_headers());
    if (body != null) {
      request.headers['content-type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final response = await _client.send(request);
    final text = await response.stream.bytesToString();
    Map<String, dynamic> decoded = {};
    if (text.isNotEmpty) {
      try {
        decoded = Map<String, dynamic>.from(jsonDecode(text) as Map);
      } catch (_) {
        throw CloudApiException('INVALID_SERVER_RESPONSE', response.statusCode);
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = decoded['error']?.toString() ?? 'REQUEST_FAILED';
      throw CloudApiException(code, response.statusCode);
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _authenticated(Map<String, dynamic> data) async {
    final token = data['sessionToken'];
    if (!kIsWeb && token is String && token.isNotEmpty) {
      _sessionToken = token;
      await prefs.setString('cloud_session_token', token);
    }
    final user = data['user'];
    currentUser = user is Map ? Map<String, dynamic>.from(user) : null;
    isSignedIn = currentUser != null;
    return currentUser ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final data = await _request('POST', '/api/auth/register', body: {
      'displayName': displayName,
      'email': email,
      'password': password,
    });
    return _authenticated(data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _request('POST', '/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _authenticated(data);
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    try {
      final data = await _request('GET', '/api/auth/me');
      final user = data['user'];
      currentUser = user is Map ? Map<String, dynamic>.from(user) : null;
      isSignedIn = currentUser != null;
      return currentUser;
    } on CloudApiException catch (error) {
      if (error.statusCode == 401) {
        isSignedIn = false;
        currentUser = null;
        if (!kIsWeb) {
          _sessionToken = null;
          await prefs.remove('cloud_session_token');
        }
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/api/auth/logout', body: {});
    } finally {
      isSignedIn = false;
      currentUser = null;
      _sessionToken = null;
      await prefs.remove('cloud_session_token');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _request('POST', '/api/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword(String token, String password) async {
    await _request('POST', '/api/auth/reset-password', body: {
      'token': token,
      'password': password,
    });
    isSignedIn = false;
    currentUser = null;
    _sessionToken = null;
    await prefs.remove('cloud_session_token');
  }

  Future<List<Map<String, dynamic>>> fetchListings() async {
    final data = await _request('GET', '/api/listings');
    final items = data['items'] as List? ?? const [];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> listing) async {
    final data = await _request('POST', '/api/listings', body: listing);
    return Map<String, dynamic>.from(data['item'] as Map);
  }

  Future<void> deleteListing(String id) async {
    await _request('DELETE', '/api/listings/' + Uri.encodeComponent(id));
  }

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final data = await _request('GET', '/api/posts');
    final items = data['items'] as List? ?? const [];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createPost(String content) async {
    final data = await _request('POST', '/api/posts', body: {'content': content});
    return Map<String, dynamic>.from(data['item'] as Map);
  }

  void dispose() => _client.close();
}