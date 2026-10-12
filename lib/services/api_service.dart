import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/canteen.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  // Live Vercel Production Server URL
  static const String baseUrl = 'https://collegecantin.vercel.app';

  // Fetch list of active canteens
  static Future<List<CanteenModel>> fetchCanteens() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tenants'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List rawList = data['tenants'] ?? [];
          return rawList.map((c) => CanteenModel.fromJson(c)).toList();
        }
      }
    } catch (e) {
      print('Error fetching canteens: $e');
    }
    return [];
  }

  // Fetch food menu for specific canteen outlet
  static Future<List<MenuItemModel>> fetchMenuItems(String tenantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/menu'),
        headers: {'X-Tenant-ID': tenantId},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List rawList = data['items'] ?? [];
          return rawList.map((i) => MenuItemModel.fromJson(i)).toList();
        }
      }
    } catch (e) {
      print('Error fetching menu items: $e');
    }
    return [];
  }

  // Submit order & generate cryptographic single-use QR token
  static Future<OrderModel?> submitOrder({
    required String tenantId,
    required String studentName,
    required String rollNo,
    required String phone,
    required String email,
    required List<CartItem> cartItems,
    required double subtotal,
    required double platformFee,
    required double totalAmount,
  }) async {
    try {
      final payload = {
        'tenantId': tenantId,
        'userStudentName': studentName,
        'studentRollNo': rollNo,
        'studentPhone': phone,
        'studentEmail': email,
        'items': cartItems.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'platformFee': platformFee,
        'totalAmount': totalAmount,
        'paymentMethod': 'ONLINE_UPI'
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'X-Tenant-ID': tenantId,
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['order'] != null) {
          return OrderModel.fromJson(data['order']);
        }
      }
    } catch (e) {
      print('Error submitting order: $e');
    }
    return null;
  }

  // Check order status to update QR screen to CLAIMED in real-time
  static Future<OrderModel?> checkOrderStatus(String orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/orders/$orderId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['order'] != null) {
          return OrderModel.fromJson(data['order']);
        }
      }
    } catch (e) {
      print('Error checking order status: $e');
    }
    return null;
  }
}
