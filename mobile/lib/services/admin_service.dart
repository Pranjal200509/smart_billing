import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/admin_stats_model.dart';
import '../models/bill_model.dart';
import '../models/complaint_model.dart';
import '../models/service_request_model.dart';
import '../models/user_profile_model.dart';

class AdminService {
  static Future<AdminStatsModel> getOverview() async {
    final response = await ApiClient.get(ApiEndpoints.adminReports);
    return AdminStatsModel.fromJson(response);
  }

  static Future<List<UserProfileModel>> getAllUsers() async {
    final response = await ApiClient.get(ApiEndpoints.adminUsers);
    if (response is List) {
      return response.map((item) => UserProfileModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<String> submitMeterReading({
    required String consumerNumber,
    required double readingValue,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.adminReadings,
      body: {
        'consumerNumber': consumerNumber.trim(),
        'readingValue': readingValue,
      },
    );
    return response['message'] ?? 'Reading logged successfully';
  }

  static Future<BillModel> generateBill({
    required int userId,
    required String billingMonthIso, // e.g. "2026-05-01"
  }) async {
    final url = '${ApiEndpoints.adminGenerateBill}?userId=$userId&billingMonth=$billingMonthIso';
    final response = await ApiClient.post(url);
    return BillModel.fromJson(response);
  }

  static Future<List<ComplaintModel>> getAllComplaints() async {
    final response = await ApiClient.get(ApiEndpoints.adminComplaints);
    if (response is List) {
      return response.map((item) => ComplaintModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<ComplaintModel> resolveComplaint({
    required int id,
    required String resolutionDetails,
    required String status,
  }) async {
    final url = '${ApiEndpoints.adminResolveComplaint(id)}?resolutionDetails=${Uri.encodeComponent(resolutionDetails)}&status=$status';
    final response = await ApiClient.put(url);
    return ComplaintModel.fromJson(response);
  }

  static Future<List<ServiceRequestModel>> getAllServiceRequests() async {
    final response = await ApiClient.get(ApiEndpoints.adminServiceRequests);
    if (response is List) {
      return response.map((item) => ServiceRequestModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<ServiceRequestModel> updateServiceRequestStatus({
    required int id,
    required String status,
  }) async {
    final url = '${ApiEndpoints.adminUpdateServiceRequestStatus(id)}?status=$status';
    final response = await ApiClient.put(url);
    return ServiceRequestModel.fromJson(response);
  }

  static Future<List<Map<String, dynamic>>> getPayments() async {
    final response = await ApiClient.get(ApiEndpoints.adminPayments);
    if (response is List) {
      return response.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }
}
