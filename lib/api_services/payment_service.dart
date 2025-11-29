import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../Others/midtrans_webview.dart';
import 'package:azza_service/config/api_config.dart';

class PaymentService {
  // Environment Configuration
  static const bool _useMidtrans = true;
  static const bool _isProduction = false;

  // Public getter
  static bool get isProduction => _isProduction;
  static bool get useMidtrans => _useMidtrans;

  // Midtrans Configuration
  static const String _devClientKey = 'Mid-client-yKTO-_jT2d60u3M1';
  static const String _prodClientKey = 'YOUR_PRODUCTION_CLIENT_KEY';

  // Dynamic URLs
  static String get baseUrl => ApiConfig.apiBaseUrl;
  static String get webhookUrl => ApiConfig.webhookBaseUrl;
  static String get midtransClientKey => _isProduction ? _prodClientKey : _devClientKey;

  static Future<Map<String, dynamic>> createPaymentCharge({
    required String orderId,
    required String customerId,
    required double totalPrice,
    required double totalPayment,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    double? shippingCost,  // ✅ Optional, default null
    bool? isPointExchange,
    int? pointsRequired,
    double? customerLat,
    double? customerLng,
  }) async {
    if (!_useMidtrans) {
      debugPrint('⚠️ [PaymentService] Midtrans disabled');
      return {'success': true, 'message': 'Simulated'};
    }

    final url = Uri.parse('$baseUrl/payment/charge');

    try {
      final requestBody = {
        'order_id': orderId,
        'customer_id': customerId,
        'total_price': totalPrice,
        'total_payment': totalPayment,
        'items': items,
        'delivery_address': deliveryAddress,
        // ✅ Hanya kirim shipping_cost jika ada DAN bukan untuk payment shipping saja
        // Untuk kasus ini, jangan kirim karena sudah include di items
        if (isPointExchange != null) 'isPointExchange': isPointExchange,
        if (pointsRequired != null) 'pointsRequired': pointsRequired,
        if (customerLat != null) 'customer_lat': customerLat,
        if (customerLng != null) 'customer_lng': customerLng,
      };

      debugPrint('════════════════════════════════════════════');
      debugPrint('📤 [createPaymentCharge] URL: $url');
      debugPrint('📤 [createPaymentCharge] Body: ${jsonEncode(requestBody)}');
      debugPrint('════════════════════════════════════════════');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 [createPaymentCharge] Status: ${response.statusCode}');
      debugPrint('📥 [createPaymentCharge] Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return {
            'success': true,
            'redirect_url': data['redirect_url'] ?? data['midtrans_redirect_url'],
            'order_code': data['order_code'],
            'transaction_id': data['transaction_id'] ?? data['midtrans_transaction_id'],
          };
        } else {
          throw Exception(data['message'] ?? 'Gagal membuat pembayaran');
        }
      } else {
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values.map((e) => e is List ? e.first : e).join(', ');
          throw Exception('Validasi gagal: $errorMessages');
        }
        throw Exception(data['message'] ?? data['error'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [createPaymentCharge] Error: $e');
      rethrow;
    }
  }

  /// 🔹 Start Midtrans Payment dengan WebView
  /// Wrapper method yang lebih simple untuk dipanggil dari checkout
  static Future<void> startMidtransPayment({
    required BuildContext context,
    required String orderId,
    required int amount,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    List<Map<String, dynamic>>? itemDetails,
    String? transKode,
    String? paymentType,
    String? deliveryAddress,  // ✅ ADDED
    required Function(String) onTransactionFinished,
  }) async {
    debugPrint('════════════════════════════════════════════');
    debugPrint('🚀 [startMidtransPayment] STARTING');
    debugPrint('════════════════════════════════════════════');
    debugPrint('📦 Order ID: $orderId');
    debugPrint('💰 Amount: Rp $amount');
    debugPrint('👤 Customer: $customerId');
    debugPrint('🔧 Use Midtrans: $_useMidtrans');
    debugPrint('════════════════════════════════════════════');

    try {
      // ✅ Convert itemDetails ke format yang diharapkan backend
      final items = itemDetails?.map((item) => {
        'kode_barang': item['id']?.toString() ?? item['kode_barang']?.toString() ?? 'ITEM',
        'nama_produk': item['name']?.toString() ?? item['nama_produk']?.toString() ?? 'Product',
        'quantity': item['quantity'] ?? 1,
        'price': item['price'] ?? amount,
        'subtotal': (item['price'] ?? amount) * (item['quantity'] ?? 1),
      }).toList() ?? [
        {
          'kode_barang': 'SHIPPING',
          'nama_produk': 'Ongkos Kirim',
          'quantity': 1,
          'price': amount,
          'subtotal': amount,
        }
      ];

      debugPrint('📦 [startMidtransPayment] Items: $items');

      // ✅ Call createPaymentCharge dengan format yang benar
      final paymentData = await createPaymentCharge(
        orderId: orderId,
        customerId: customerId,
        totalPrice: amount.toDouble(),
        totalPayment: amount.toDouble(),
        items: items,
        deliveryAddress: deliveryAddress ?? 'Alamat tidak tersedia',  // ✅ ADDED
        shippingCost: paymentType == 'shipping' ? amount.toDouble() : null,
        isPointExchange: paymentType == 'points' || paymentType == 'shipping',
      );

      debugPrint('📥 [startMidtransPayment] Payment data: $paymentData');

      // ✅ Check if redirect_url exists
      if (!paymentData.containsKey('redirect_url') || paymentData['redirect_url'] == null) {
        debugPrint('⚠️ [startMidtransPayment] No redirect_url, simulating success');
        onTransactionFinished('success');
        return;
      }

      final redirectUrl = paymentData['redirect_url'];
      debugPrint('🔗 [startMidtransPayment] Redirect URL: $redirectUrl');
      debugPrint('🔓 [startMidtransPayment] Opening WebView...');

      // ✅ Show WebView with Midtrans Snap
      if (context.mounted) {
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => MidtransWebView(
            redirectUrl: redirectUrl,
            orderId: orderId,
            onTransactionFinished: (status) {
              debugPrint('💳 [MidtransWebView] Callback status: $status');
            },
          ),
        );

        debugPrint('💳 [startMidtransPayment] WebView closed with result: $result');
        onTransactionFinished(result ?? 'cancel');
      } else {
        debugPrint('❌ [startMidtransPayment] Context not mounted!');
        onTransactionFinished('error');
      }

    } catch (e) {
      debugPrint('❌ [startMidtransPayment] Error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka pembayaran: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      onTransactionFinished('error');
    }
  }

  /// 🔹 Start payment specifically for shipping cost (point exchange)
  static Future<void> startShippingPayment({
    required BuildContext context,
    required String orderCode,
    required String customerId,
    required double shippingCost,
    required String customerName,
    required String customerPhone,
    required int pointsUsed,
    required String deliveryAddress,
    double? customerLat,
    double? customerLng,
    required Function(String) onTransactionFinished,
  }) async {
    debugPrint('════════════════════════════════════════════');
    debugPrint('🚚 [startShippingPayment] STARTING');
    debugPrint('════════════════════════════════════════════');
    debugPrint('📦 Order Code: $orderCode');
    debugPrint('💰 Shipping Cost: Rp ${shippingCost.toStringAsFixed(0)}');
    debugPrint('════════════════════════════════════════════');

    if (shippingCost <= 0) {
      debugPrint('✅ No shipping cost, success directly');
      onTransactionFinished('success');
      return;
    }

    try {
      final items = [
        {
          'kode_barang': 'SHIPPING',
          'nama_produk': 'Ongkos Kirim',
          'quantity': 1,
          'price': shippingCost,
          'subtotal': shippingCost,
        }
      ];

      final midtransOrderId = '${orderCode}_SHIP_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('🆔 [startShippingPayment] Midtrans Order ID: $midtransOrderId');
      debugPrint('📦 [startShippingPayment] Items: $items');

      // ✅ FIXED: Tidak kirim shipping_cost terpisah karena sudah di items
      final paymentData = await createPaymentCharge(
        orderId: midtransOrderId,
        customerId: customerId,
        totalPrice: 0,
        totalPayment: shippingCost,
        items: items,
        deliveryAddress: deliveryAddress,
        // ✅ REMOVED: shipping_cost (sudah include di items)
        // shippingCost: shippingCost,  // ❌ JANGAN KIRIM INI
        isPointExchange: true,
        pointsRequired: pointsUsed,
        customerLat: customerLat,
        customerLng: customerLng,
      );

      debugPrint('📥 [startShippingPayment] Payment data: $paymentData');

      if (!paymentData.containsKey('redirect_url') || paymentData['redirect_url'] == null) {
        throw Exception('Tidak mendapatkan URL pembayaran dari server');
      }

      final redirectUrl = paymentData['redirect_url'];
      debugPrint('🔗 [startShippingPayment] Redirect URL: $redirectUrl');

      if (context.mounted) {
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => MidtransWebView(
            redirectUrl: redirectUrl,
            orderId: midtransOrderId,
            onTransactionFinished: (status) {
              debugPrint('💳 [MidtransWebView] Status: $status');
            },
          ),
        );

        debugPrint('💳 [startShippingPayment] Final result: $result');
        onTransactionFinished(result ?? 'cancel');
      } else {
        onTransactionFinished('error');
      }

    } catch (e) {
      debugPrint('❌ [startShippingPayment] Error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka pembayaran: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      onTransactionFinished('error');
    }
  }

  // ========== HELPER METHODS ==========

  /// Check payment status
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

  /// Get payment history
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

  /// Check if transaction is successful
  static bool isTransactionSuccess(dynamic status) {
    if (status == null) return false;

    final statusStr = status.toString().toLowerCase();

    if (statusStr.isEmpty || statusStr == 'cancel' || statusStr == 'failure' || statusStr == 'error') {
      return false;
    }

    return statusStr == 'capture' ||
           statusStr == 'settlement' ||
           statusStr == 'success';
  }

  /// Get user-friendly status message
  static String getStatusMessage(dynamic status) {
    if (status == null) return 'Status tidak diketahui';

    final statusStr = status.toString().toLowerCase();

    if (statusStr.isEmpty) return 'Pembayaran dibatalkan';

    switch (statusStr) {
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
      case 'error':
        return 'Terjadi kesalahan';
      default:
        return 'Status: $status';
    }
  }
}
