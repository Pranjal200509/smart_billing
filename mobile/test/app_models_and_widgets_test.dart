import 'package:electricity_billing/core/widgets/custom_button.dart';
import 'package:electricity_billing/core/widgets/metric_card.dart';
import 'package:electricity_billing/core/widgets/status_badge.dart';
import 'package:electricity_billing/core/storage/session_manager.dart';
import 'package:electricity_billing/models/admin_stats_model.dart';
import 'package:electricity_billing/models/auth_model.dart';
import 'package:electricity_billing/models/bill_model.dart';
import 'package:electricity_billing/models/complaint_model.dart';
import 'package:electricity_billing/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Model Serialization Tests', () {
    test('JwtResponse parses json correctly', () {
      final json = {
        'token': 'mock-jwt-token-12345',
        'id': 1,
        'fullName': 'Pranjal Pawar',
        'email': 'pranjal@gmail.com',
        'role': 'ROLE_USER',
        'customerId': 'CUST-2026-001',
      };

      final response = JwtResponse.fromJson(json);
      expect(response.token, 'mock-jwt-token-12345');
      expect(response.id, 1);
      expect(response.fullName, 'Pranjal Pawar');
      expect(response.email, 'pranjal@gmail.com');
      expect(response.role, 'ROLE_USER');
      expect(response.customerId, 'CUST-2026-001');
    });

    test('UserProfileModel parses full profile data correctly', () {
      final json = {
        'id': 2,
        'customerId': 'CUST-2026-002',
        'fullName': 'Test Consumer',
        'email': 'consumer@test.com',
        'mobileNumber': '9876543210',
        'address': 'Flat 402, Green Valley',
        'city': 'Pune',
        'state': 'Maharashtra',
        'pinCode': '411001',
        'connectionType': 'Residential',
        'loadCapacityKw': 5.0,
        'status': 'VERIFIED',
        'meterNumber': 'MTR123456',
        'consumerNumber': '987654321012',
        'currentReadingKwh': 2500.0,
        'meterStatus': 'ACTIVE',
      };

      final profile = UserProfileModel.fromJson(json);
      expect(profile.id, 2);
      expect(profile.fullName, 'Test Consumer');
      expect(profile.meterNumber, 'MTR123456');
      expect(profile.loadCapacityKw, 5.0);
      expect(profile.currentReadingKwh, 2500.0);
    });

    test('BillModel parses calculation fields accurately', () {
      final json = {
        'id': 10,
        'billNumber': 'BILL-202607-001',
        'billingMonth': 'July 2026',
        'previousReadingKwh': 2250.0,
        'currentReadingKwh': 2500.0,
        'unitsConsumed': 250.0,
        'energyCharge': 1500.0,
        'fixedCharge': 250.0,
        'taxes': 150.0,
        'lateFee': 0.0,
        'totalAmount': 1900.0,
        'dueDate': '2026-08-15',
        'paymentStatus': 'PENDING',
        'consumerNumber': '987654321012',
      };

      final bill = BillModel.fromJson(json);
      expect(bill.billNumber, 'BILL-202607-001');
      expect(bill.unitsConsumed, 250.0);
      expect(bill.totalAmount, 1900.0);
      expect(bill.paymentStatus, 'PENDING');
    });

    test('AdminStatsModel parses KPI metrics correctly', () {
      final json = {
        'totalCustomers': 45,
        'totalBilledAmount': 185000.0,
        'totalRevenueCollected': 142000.0,
        'pendingBillsCount': 12,
        'overdueBillsCount': 3,
        'complaintsStatus': '8/10',
        'totalServiceRequests': 5,
      };

      final stats = AdminStatsModel.fromJson(json);
      expect(stats.totalCustomers, 45);
      expect(stats.totalRevenueCollected, 142000.0);
      expect(stats.pendingBillsCount, 12);
      expect(stats.overdueBillsCount, 3);
      expect(stats.complaintsStatus, '8/10');
    });

    test('ComplaintModel parses ticket data', () {
      final json = {
        'id': 101,
        'complaintId': 'CMP202608-01',
        'complaintType': 'Power Failure',
        'description': 'Frequent power trips in Phase 2',
        'status': 'RESOLVED',
        'resolutionDetails': 'Transformer capacitor replaced',
      };

      final c = ComplaintModel.fromJson(json);
      expect(c.complaintId, 'CMP202608-01');
      expect(c.status, 'RESOLVED');
      expect(c.resolutionDetails, 'Transformer capacitor replaced');
    });
  });

  group('Reusable Widget Tests', () {
    testWidgets('CustomButton renders text and triggers callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Submit Reading',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Reading'), findsOneWidget);
      await tester.tap(find.text('Submit Reading'));
      expect(tapped, isTrue);
    });

    testWidgets('StatusBadge renders correct status and style', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'PAID'),
          ),
        ),
      );

      expect(find.text('PAID'), findsOneWidget);
    });

    testWidgets('MetricCard displays title, value, and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              title: 'Active Accounts',
              value: '128',
              icon: Icons.people,
            ),
          ),
        ),
      );

      expect(find.text('Active Accounts'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });
  });

  group('SessionManager and Startup Tests', () {
    test('isTokenExpired correctly handles invalid format and valid payload', () {
      expect(SessionManager.isTokenExpired(''), isTrue);
      expect(SessionManager.isTokenExpired('not-a-valid-token'), isTrue);

      // Create a mock expired token: payload {"sub":"admin@gmail.com","exp":1000} (expired in 1970)
      // Base64 header: eyJhbGciOiJIUzI1NiJ9
      // Base64 payload for {"sub":"admin@gmail.com","exp":1000}: eyJzdWIiOiJhZG1pbkBnbWFpbC5jb20iLCJleHAiOjEwMDB9
      const expiredToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBnbWFpbC5jb20iLCJleHAiOjEwMDB9.signature';
      expect(SessionManager.isTokenExpired(expiredToken), isTrue);

      // Create a mock future token: payload {"sub":"admin@gmail.com","exp":4070908800} (year 2099)
      // Base64 payload: eyJzdWIiOiJhZG1pbkBnbWFpbC5jb20iLCJleHAiOjQwNzA5MDg4MDB9
      const validToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBnbWFpbC5jb20iLCJleHAiOjQwNzA5MDg4MDB9.signature';
      expect(SessionManager.isTokenExpired(validToken), isFalse);
    });
  });
}

