import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';

/// Centralized, platform-aware API configuration.
///
/// Automatic host mapping:
/// - Android Emulator   → http://10.0.2.2:8080
/// - Chrome / Web       → http://127.0.0.1:8080
/// - Windows / Desktop  → http://127.0.0.1:8080
/// - Physical Android   → http://[PC_LAN_IP]:8080 (PC Wi-Fi LAN IPv4 address)
class ApiEndpoints {
  ApiEndpoints._();

  static const int defaultPort = 8080;

  /// PC's Wi-Fi LAN IPv4 address for physical Android devices on the same network.
  /// Overridable at compile-time via --dart-define=BACKEND_HOST=...
  static const String localLanIp = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '172.25.21.132',
  );

  static String? _resolvedHost;
  static String? _inMemoryBaseUrl;

  /// Resolves the dedicated base host for the current platform/device automatically.
  static Future<String> resolvePlatformHost() async {
    if (kIsWeb) {
      return 'http://127.0.0.1:$defaultPort';
    }
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final model = androidInfo.model.toLowerCase();
        final hardware = androidInfo.hardware.toLowerCase();
        final brand = androidInfo.brand.toLowerCase();
        final fingerprint = androidInfo.fingerprint.toLowerCase();

        final isEmulator = !androidInfo.isPhysicalDevice ||
            model.contains('sdk') ||
            model.contains('emulator') ||
            model.contains('google_sdk') ||
            hardware.contains('goldfish') ||
            hardware.contains('ranchu') ||
            brand.contains('generic') ||
            fingerprint.startsWith('generic');

        if (isEmulator) {
          // Android Emulator host loopback alias
          return 'http://10.0.2.2:$defaultPort';
        } else {
          // Physical Android device connected to the same Wi-Fi network
          return 'http://$localLanIp:$defaultPort';
        }
      }
      if (Platform.isIOS) {
        return 'http://127.0.0.1:$defaultPort';
      }
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return 'http://127.0.0.1:$defaultPort';
      }
    } catch (_) {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:$defaultPort';
      }
    }
    return 'http://127.0.0.1:$defaultPort';
  }

  /// Synchronous default host derived from platform before async initialization.
  static String get defaultHost {
    if (_resolvedHost != null && _resolvedHost!.isNotEmpty) {
      return _resolvedHost!;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:$defaultPort';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:$defaultPort';
      }
      return 'http://127.0.0.1:$defaultPort';
    } catch (_) {
      return 'http://127.0.0.1:$defaultPort';
    }
  }

  static void setResolvedHost(String host) {
    _resolvedHost = host;
  }

  // ── Runtime override ──────────────────────────────────────────────────────
  /// Overrides the base URL at runtime (strips trailing slash, appends /api/v1).
  static void setBaseUrl(String url) {
    var formatted = url.trim();
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (!formatted.endsWith('/api/v1')) {
      formatted = '$formatted/api/v1';
    }
    _inMemoryBaseUrl = formatted;
  }

  static String get baseUrl {
    if (_inMemoryBaseUrl != null && _inMemoryBaseUrl!.isNotEmpty) {
      return _inMemoryBaseUrl!;
    }
    return '$defaultHost/api/v1';
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static String get login            => '$baseUrl/auth/login';
  static String get register         => '$baseUrl/auth/register';
  static String get forgotPassword   => '$baseUrl/auth/forgot-password';
  static String get verifyOtp        => '$baseUrl/auth/verify-otp';
  static String get resetPassword    => '$baseUrl/auth/reset-password';
  static String get health           => '$baseUrl/health';

  // ── Consumer ──────────────────────────────────────────────────────────────
  static String get userProfile          => '$baseUrl/user/profile';
  static String get currentBill          => '$baseUrl/bills/current';
  static String get billsHistory         => '$baseUrl/bills/history';
  static String get payBill              => '$baseUrl/bills/pay';
  static String get razorpayCreateOrder  => '$baseUrl/bills/razorpay/create-order';
  static String get razorpayVerifyPayment => '$baseUrl/bills/razorpay/verify-payment';
  static String get usageOverview        => '$baseUrl/usage/overview';
  static String get usageChartData       => '$baseUrl/usage/chart-data';
  static String get complaints           => '$baseUrl/complaints';
  static String get serviceRequests      => '$baseUrl/service-requests';
  static String get notifications        => '$baseUrl/notifications';
  static String readNotification(int id) => '$baseUrl/notifications/$id/read';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static String get adminUsers         => '$baseUrl/admin/users';
  static String get adminReadings      => '$baseUrl/admin/readings';
  static String get adminGenerateBill  => '$baseUrl/admin/bills/generate';
  static String get adminComplaints    => '$baseUrl/admin/complaints';
  static String adminResolveComplaint(int id) =>
      '$baseUrl/admin/complaints/$id/resolve';
  static String get adminServiceRequests => '$baseUrl/admin/service-requests';
  static String adminUpdateServiceRequestStatus(int id) =>
      '$baseUrl/admin/service-requests/$id/status';
  static String get adminReports   => '$baseUrl/admin/reports/overview';
  static String get adminPayments  => '$baseUrl/admin/payments';
}
