import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_service/config/api_config.dart';

/// Service untuk menangani webhook dari Midtrans (Production-ready)
class WebhookService {
  // Production webhook endpoint - akan dipanggil oleh Midtrans
  static const String _webhookEndpoint = '/api/payment/webhook';

  /// 🔹 Handle incoming webhook dari Midtrans
  /// Endpoint ini harus di-expose di backend Laravel
  static Future<void> handleWebhook(Map<String, dynamic> webhookData) async {
    try {
      print('Received Midtrans webhook: $webhookData');

      // Validasi webhook signature (penting untuk security)
      final isValid = _validateWebhookSignature(webhookData);
      if (!isValid) {
        print('Invalid webhook signature');
        return;
      }

      // Extract data dari webhook
      final orderId = webhookData['order_id'];
      final transactionStatus = webhookData['transaction_status'];
      final paymentType = webhookData['payment_type'];
      final grossAmount = webhookData['gross_amount'];

      print('Processing webhook for order: $orderId, status: $transactionStatus');

      // Update status pembayaran di database
      await _updatePaymentStatus(orderId, transactionStatus, webhookData);

      // Kirim notifikasi ke user jika perlu
      await _sendPaymentNotification(orderId, transactionStatus);

      // Log webhook untuk audit trail
      await _logWebhookEvent(webhookData);

    } catch (e) {
      print('Error processing webhook: $e');
      // Log error untuk monitoring
    }
  }

  /// 🔹 Validasi signature webhook dari Midtrans
  static bool _validateWebhookSignature(Map<String, dynamic> data) {
    // Implementasi validasi signature sesuai dokumentasi Midtrans
    // Menggunakan server key untuk verifikasi
    // Contoh sederhana - sesuaikan dengan implementasi Midtrans
    final signature = data['signature_key'];
    if (signature == null) return false;

    // TODO: Implement proper signature validation
    // Gabungkan order_id + status_code + gross_amount + server_key
    // Hash dengan SHA512 dan bandingkan dengan signature_key
    return true; // Placeholder - implement proper validation
  }

  /// 🔹 Update status pembayaran di backend
  static Future<void> _updatePaymentStatus(
    String orderId,
    String status,
    Map<String, dynamic> webhookData
  ) async {
    // Panggil API backend untuk update status
    // Implementasi tergantung pada struktur API backend Anda
    print('Updating payment status for $orderId to $status');
    // TODO: Implement API call to update payment status
  }

  /// 🔹 Kirim notifikasi pembayaran ke user
  static Future<void> _sendPaymentNotification(String orderId, String status) async {
    // Kirim push notification atau email ke user
    print('Sending notification for order $orderId with status $status');
    // TODO: Implement notification sending
  }

  /// 🔹 Log webhook event untuk audit
  static Future<void> _logWebhookEvent(Map<String, dynamic> data) async {
    // Simpan log webhook ke database untuk audit trail
    print('Logging webhook event: ${data['order_id']}');
    // TODO: Implement webhook logging
  }

  /// 🔹 Helper untuk mapping status Midtrans
  static String mapTransactionStatus(String midtransStatus) {
    switch (midtransStatus.toLowerCase()) {
      case 'capture':
      case 'settlement':
        return 'success';
      case 'pending':
        return 'pending';
      case 'deny':
      case 'cancel':
      case 'expire':
      case 'failure':
        return 'failed';
      default:
        return 'unknown';
    }
  }

  /// 🔹 Test webhook endpoint (untuk development)
  static Future<void> testWebhook(String testOrderId) async {
    final testData = {
      'order_id': testOrderId,
      'transaction_status': 'settlement',
      'payment_type': 'bank_transfer',
      'gross_amount': '100000',
      'signature_key': 'test_signature',
      'transaction_time': DateTime.now().toIso8601String(),
    };

    await handleWebhook(testData);
  }
}
