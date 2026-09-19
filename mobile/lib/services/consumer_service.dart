import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/bill_model.dart';
import '../models/complaint_model.dart';
import '../models/notification_model.dart';
import '../models/service_request_model.dart';
import '../models/usage_model.dart';
import '../models/user_profile_model.dart';

class ConsumerService {
  static Future<UserProfileModel> getProfile() async {
    final response = await ApiClient.get(ApiEndpoints.userProfile);
    return UserProfileModel.fromJson(response);
  }

  static Future<String> updateProfile({
    required String fullName,
    required String mobileNumber,
    required String address,
    required String city,
    required String state,
    required String pinCode,
  }) async {
    final response = await ApiClient.put(
      ApiEndpoints.userProfile,
      body: {
        'fullName': fullName.trim(),
        'mobileNumber': mobileNumber.trim(),
        'address': address.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'pinCode': pinCode.trim(),
      },
    );
    return response['message'] ?? 'Profile updated successfully';
  }

  static Future<BillModel> getCurrentBill() async {
    final response = await ApiClient.get(ApiEndpoints.currentBill);
    return BillModel.fromJson(response);
  }

  static Future<List<BillModel>> getBillsHistory() async {
    final response = await ApiClient.get(ApiEndpoints.billsHistory);
    if (response is List) {
      return response.map((item) => BillModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> payBill({
    required int billId,
    required String paymentMethod,
    required double amountPaid,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.payBill,
      body: {
        'billId': billId,
        'paymentMethod': paymentMethod,
        'amountPaid': amountPaid,
      },
    );
    return response is Map<String, dynamic> ? response : {};
  }

  static Future<Map<String, dynamic>> createRazorpayOrder(int billId) async {
    final response = await ApiClient.post(
      ApiEndpoints.razorpayCreateOrder,
      body: {
        'billId': billId,
      },
    );
    return response is Map<String, dynamic> ? response : {};
  }

  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required int billId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.razorpayVerifyPayment,
      body: {
        'billId': billId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
      },
    );
    return response is Map<String, dynamic> ? response : {};
  }


  static Future<UsageOverviewModel> getUsageOverview() async {
    final response = await ApiClient.get(ApiEndpoints.usageOverview);
    return UsageOverviewModel.fromJson(response);
  }

  static Future<List<UsageChartPoint>> getUsageChartData() async {
    final response = await ApiClient.get(ApiEndpoints.usageChartData);
    if (response is List) {
      return response.map((item) => UsageChartPoint.fromJson(item)).toList();
    }
    return [];
  }

  static Future<ComplaintModel> submitComplaint({
    required String complaintType,
    required String description,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.complaints,
      body: {
        'complaintType': complaintType,
        'description': description.trim(),
      },
    );
    return ComplaintModel.fromJson(response);
  }

  static Future<List<ComplaintModel>> getComplaints() async {
    final response = await ApiClient.get(ApiEndpoints.complaints);
    if (response is List) {
      return response.map((item) => ComplaintModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<ServiceRequestModel> submitServiceRequest({
    required String requestType,
    required String details,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.serviceRequests,
      body: {
        'requestType': requestType,
        'details': details.trim(),
      },
    );
    return ServiceRequestModel.fromJson(response);
  }

  static Future<List<ServiceRequestModel>> getServiceRequests() async {
    final response = await ApiClient.get(ApiEndpoints.serviceRequests);
    if (response is List) {
      return response.map((item) => ServiceRequestModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<List<NotificationModel>> getNotifications() async {
    final response = await ApiClient.get(ApiEndpoints.notifications);
    if (response is List) {
      return response.map((item) => NotificationModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    await ApiClient.put(ApiEndpoints.readNotification(notificationId));
  }
}
