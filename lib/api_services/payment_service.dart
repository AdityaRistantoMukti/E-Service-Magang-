import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../Others/midtrans_webview.dart';

import 'package:e_service/config/api_config.dart';

class PaymentService {
  // Environment Configuration
  static const bool _isProduction = false; // Set to true for production

  // Midtrans Configuration
  static const String _devClientKey = 'Mid-client-yKTO-_jT2d60u3M1';
  static const String _prodClientKey = 'YOUR_PRODUCTION_CLIENT_KEY'; // Update with production key

  // Dynamic URLs based on environment
  static String get baseUrl => ApiConfig.apiBaseUrl;
  static String get webhookUrl => ApiConfig.webhookBaseUrl;
  static String get midtransClientKey => _isProduction ? _prodClientKey : _devClientKey;

  /// 🔹 Buat transaksi ke backend
  static Future<Map<String, dynamic>> createPayment({
    required String customerId,
    required int amount,
    String? kodeBarang,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? orderId,
    List<Map<String, dynamic>>? itemDetails,
  }) async {
    final url = Uri.parse('$baseUrl/payment/charge');

    try {
      final requestBody = {
        'id_costomer': customerId,
        'amount': amount,
        'kode_barang': kodeBarang ?? '34GM',
        // Tambahkan data lengkap untuk Midtrans transaction
        'transaction_details': {
          'order_id': orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}',
          'gross_amount': amount,
        },
        'customer_details': {
          'first_name': customerName ?? 'Customer',
          'email': customerEmail ?? 'customer@example.com',
          'phone': customerPhone ?? '08123456789',
        },
        'item_details': itemDetails ?? [
          {
            'id': kodeBarang ?? '34GM',
            'price': amount,
            'quantity': 1,
            'name': 'Service Repair',
          }
        ],
        // Production-ready: Include webhook URL for real-time notifications
        if (_isProduction) 'notification_url': webhookUrl,
      };

      print('Payment request to: $url');
      print('Request body: $requestBody');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal membuat pembayaran');
      }
    } catch (e) {
      print('Full error in createPayment: $e');
      throw Exception('Error creating payment: $e');
    }
  }

  /// 🔹 Jalankan UI pembayaran Midtrans menggunakan WebView
  static Future<void> startMidtransPayment({
    required BuildContext context,
    required String orderId,
    required int amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    List<Map<String, dynamic>>? itemDetails,
    required Function(String) onTransactionFinished,
  }) async {
    try {
      // Dapatkan redirect_url dari backend
      final paymentData = await createPayment(
        customerId: customerId,
        amount: amount,
        orderId: orderId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        itemDetails: itemDetails,
      );

      if (!paymentData.containsKey('redirect_url')) {
        throw Exception('Backend tidak mengembalikan redirect_url');
      }

      final redirectUrl = paymentData['redirect_url'];

      // Tampilkan WebView dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => MidtransWebView(
            redirectUrl: redirectUrl,
            orderId: orderId,
            onTransactionFinished: (result) {
              Navigator.of(dialogContext).pop(); // Close dialog
              onTransactionFinished(result);
            },
          ),
        );
      }

    } catch (e) {
      print('Error starting Midtrans payment: $e');

      // Tampilkan error ke user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// 🔹 Cek status pembayaran dari backend
  static Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final url = Uri.parse('$baseUrl/payment/status/$orderId');
    
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Gagal mendapatkan status pembayaran');
      }
    } catch (e) {
      throw Exception('Error getting payment status: $e');
    }
  }

  /// 🔹 Ambil riwayat pembayaran customer
  static Future<List<dynamic>> getPaymentHistory(String customerId) async {
    final url = Uri.parse('$baseUrl/payment/history/$customerId');
    
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Gagal mendapatkan riwayat pembayaran');
      }
    } catch (e) {
      throw Exception('Error getting payment history: $e');
    }
  }
  

  /// 🔹 Helper untuk mengecek apakah transaksi sukses
  static bool isTransactionSuccess(String status) {
    // Status yang valid dari Midtrans:
    // - "capture" atau "settlement" = sukses
    // - "pending" = menunggu
    // - "deny" atau "cancel" atau "expire" = gagal

    final statusLower = status.toLowerCase();

    // Jika status kosong atau cancel, berarti gagal/dibatalkan
    if (statusLower.isEmpty || statusLower == 'cancel' || statusLower == 'failure') {
      return false;
    }

    return statusLower == 'capture' ||
           statusLower == 'settlement' ||
           statusLower == 'success';
  }

  /// 🔹 Helper untuk mendapatkan pesan status yang user-friendly
  static String getStatusMessage(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.isEmpty) {
      return 'Pembayaran dibatalkan';
    }

    switch (statusLower) {
      case 'capture':
      case 'settlement':
      case 'success':
        return 'Pembayaran berhasil';
      case 'pending':
        return 'Menunggu pembayaran';
      case 'deny':
        return 'Pembayaran ditolak';
      case 'expire':
        return 'Pembayaran kadaluarsa';
      case 'cancel':
      case 'failure':
        return 'Pembayaran dibatalkan';
      default:
        return 'Status: $status';
    }
  }
}