import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../storage/session_manager.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static const Duration _timeout = Duration(seconds: 15);
  static bool _initializedFromStorage = false;

  /// Resets initialization flag so the next call re-reads stored preferences.
  static void resetInitialization() {
    _initializedFromStorage = false;
  }

  static Future<void> ensureInitialized() async {
    if (_initializedFromStorage) return;
    try {
      final platformHost = await ApiEndpoints.resolvePlatformHost();
      ApiEndpoints.setResolvedHost(platformHost);

      final customUrl = await SessionManager.getCustomBaseUrl();
      if (customUrl != null && customUrl.isNotEmpty) {
        // Guard against invalid legacy 127.0.0.1 / localhost saved on Android
        if (!kIsWeb && Platform.isAndroid && (customUrl.contains('127.0.0.1') || customUrl.contains('localhost'))) {
          await SessionManager.setCustomBaseUrl(null);
          ApiEndpoints.setBaseUrl(platformHost);
          dev.log('[ApiClient] Discarded invalid loopback for Android, using: $platformHost', name: 'ApiClient');
        } else {
          ApiEndpoints.setBaseUrl(customUrl);
          dev.log('[ApiClient] Using custom server URL: $customUrl', name: 'ApiClient');
        }
      } else {
        ApiEndpoints.setBaseUrl(platformHost);
        dev.log('[ApiClient] Initialized platform base URL: ${ApiEndpoints.baseUrl}', name: 'ApiClient');
      }
    } catch (e) {
      dev.log('[ApiClient] Initialization exception: $e', name: 'ApiClient');
    }
    _initializedFromStorage = true;
  }

  static String _normalizeUrl(String url) {
    if (url.startsWith('/')) {
      return '${ApiEndpoints.baseUrl}$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final baseUri = Uri.parse(ApiEndpoints.baseUrl);
      // Ensure scheme, host, and port match the resolved active base URL
      final normalizedUri = uri.replace(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
      );
      return normalizedUri.toString();
    }
    return url;
  }

  static Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    await ensureInitialized();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body;
      }
    }

    if (response.statusCode == 401) {
      SessionManager.clearSession();
      throw ApiException(
          'Your session has expired or authentication failed. Please sign in again.', 401);
    }

    String errorMessage = 'Request failed with status: ${response.statusCode}';
    try {
      final errorJson = jsonDecode(response.body);
      if (errorJson is Map) {
        errorMessage = errorJson['message'] ?? errorJson['error'] ?? errorMessage;
      }
    } catch (_) {}

    throw ApiException(errorMessage, response.statusCode);
  }

  // ── Public HTTP methods ───────────────────────────────────────────────────

  static Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    await ensureInitialized();
    final effectiveUrl = _normalizeUrl(url);
    dev.log('[ApiClient] GET $effectiveUrl', name: 'ApiClient');
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response =
          await http.get(Uri.parse(effectiveUrl), headers: headers).timeout(_timeout);
      dev.log('[ApiClient] GET $effectiveUrl → ${response.statusCode}', name: 'ApiClient');
      return _handleResponse(response);
    } on Exception catch (e) {
      _rethrowHandledException('GET', effectiveUrl, e);
    }
  }

  static Future<dynamic> post(String url,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    await ensureInitialized();
    final effectiveUrl = _normalizeUrl(url);
    dev.log('[ApiClient] POST $effectiveUrl body=${body?.keys.toList()}', name: 'ApiClient');
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .post(
            Uri.parse(effectiveUrl),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      dev.log('[ApiClient] POST $effectiveUrl → ${response.statusCode}', name: 'ApiClient');
      return _handleResponse(response);
    } on Exception catch (e) {
      _rethrowHandledException('POST', effectiveUrl, e);
    }
  }

  static Future<dynamic> put(String url,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    await ensureInitialized();
    final effectiveUrl = _normalizeUrl(url);
    dev.log('[ApiClient] PUT $effectiveUrl body=${body?.keys.toList()}', name: 'ApiClient');
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .put(
            Uri.parse(effectiveUrl),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      dev.log('[ApiClient] PUT $effectiveUrl → ${response.statusCode}', name: 'ApiClient');
      return _handleResponse(response);
    } on Exception catch (e) {
      _rethrowHandledException('PUT', effectiveUrl, e);
    }
  }

  static Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    await ensureInitialized();
    final effectiveUrl = _normalizeUrl(url);
    dev.log('[ApiClient] DELETE $effectiveUrl', name: 'ApiClient');
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response =
          await http.delete(Uri.parse(effectiveUrl), headers: headers).timeout(_timeout);
      dev.log('[ApiClient] DELETE $effectiveUrl → ${response.statusCode}', name: 'ApiClient');
      return _handleResponse(response);
    } on Exception catch (e) {
      _rethrowHandledException('DELETE', effectiveUrl, e);
    }
  }

  // ── Error handling ────────────────────────────────────────────────────────

  static Never _rethrowHandledException(String method, String url, Exception e) {
    if (e is ApiException) throw e;

    if (e is SocketException) {
      dev.log('[ApiClient] SocketException on $method $url: $e', name: 'ApiClient', level: 1000);
      String hint = '';
      if (!kIsWeb) {
        hint = '\n\n• Android Emulator: http://10.0.2.2:8080\n• Physical Android Device: http://${ApiEndpoints.localLanIp}:8080\n• Chrome / Windows: http://127.0.0.1:8080';
      }
      throw ApiException('Cannot reach the server at $url.$hint');
    }

    if (e is TimeoutException) {
      dev.log('[ApiClient] TimeoutException on $method $url: $e', name: 'ApiClient', level: 1000);
      throw ApiException(
          'Connection timed out. Make sure the Spring Boot server is running on port 8080.\n\nURL tried: $url');
    }

    if (e is http.ClientException) {
      dev.log('[ApiClient] ClientException on $method $url: $e', name: 'ApiClient', level: 1000);
      final msg = e.message.toLowerCase();
      if (msg.contains('failed to fetch') || msg.contains('xmlhttprequest error')) {
        throw ApiException(
            'Could not connect to the server (CORS or network issue).\n\nMake sure the backend is running and CORS is configured.\nURL: $url');
      }
      throw ApiException('Network error on $method $url: ${e.message}');
    }

    dev.log('[ApiClient] Unexpected error on $method $url: $e', name: 'ApiClient', level: 1000);
    throw ApiException('Unexpected error: $e');
  }
}
