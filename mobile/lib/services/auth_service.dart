import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/session_manager.dart';
import '../models/auth_model.dart';

class AuthService {
  static Future<JwtResponse> login(String email, String password) async {
    final response = await ApiClient.post(
      ApiEndpoints.login,
      body: {'email': email.trim(), 'password': password.trim()},
      requiresAuth: false,
    );

    final jwtResponse = JwtResponse.fromJson(response);

    // Save session
    await SessionManager.saveSession(
      token: jwtResponse.token,
      userId: jwtResponse.id,
      fullName: jwtResponse.fullName,
      email: jwtResponse.email,
      role: jwtResponse.role,
      customerId: jwtResponse.customerId,
    );

    return jwtResponse;
  }

  static Future<String> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String consumerNumber,
    required String meterNumber,
    required String connectionType,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.register,
      body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'mobileNumber': mobileNumber.trim(),
        'consumerNumber': consumerNumber.trim(),
        'meterNumber': meterNumber.trim(),
        'connectionType': connectionType,
        'address': address.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'pinCode': pinCode.trim(),
        'password': password.trim(),
      },
      requiresAuth: false,
    );

    return response['message'] ?? 'Registration successful';
  }

  static Future<String> forgotPassword(String email) async {
    final response = await ApiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email.trim()},
      requiresAuth: false,
    );
    return response['message'] ?? 'OTP sent to registered email';
  }

  static Future<String> verifyOtp(String email, String otp) async {
    final response = await ApiClient.post(
      ApiEndpoints.verifyOtp,
      body: {'email': email.trim(), 'otp': otp.trim()},
      requiresAuth: false,
    );
    return response['token'] ?? '';
  }

  static Future<String> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.resetPassword,
      body: {
        'email': email.trim(),
        'token': token.trim(),
        'newPassword': newPassword.trim(),
      },
      requiresAuth: false,
    );
    return response['message'] ?? 'Password reset successfully';
  }

  static Future<void> logout() async {
    await SessionManager.clearSession();
  }
}
