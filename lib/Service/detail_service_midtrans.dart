import 'package:e_service/Service/Service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_alamat.dart';
import 'tracking_driver.dart';
import '../api_services/payment_service.dart';
import '../Others/session_manager.dart';

class DetailServiceMidtransPage extends StatefulWidget {
  final String serviceType;
  final String nama;
  final String? status;
  final int jumlahBarang;
  final List<Map<String, String?>> items;
  final String alamat;

  const DetailServiceMidtransPage({
    super.key,
    required this.serviceType,
    required this.nama,
    required this.status,
    required this.jumlahBarang,
    required this.items,
    required this.alamat,
  });

  @override
  State<DetailServiceMidtransPage> createState() => _DetailServiceMidtransPageState();
}

class _DetailServiceMidtransPageState extends State<DetailServiceMidtransPage> {
  String? selectedPaymentMethod;
  Map<String, dynamic>? selectedAddress;

  // --- Tambahan untuk kode antrean ---
  static int _lastQueueNumber = 0;
  late String currentQueueCode;

  // Fungsi untuk membuat kode antrean baru
  String _generateQueueCode(String serviceType) {
    _lastQueueNumber++;
    return "TTS${_lastQueueNumber.toString().padLeft(3, '0')}-$serviceType";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Ringkasan Pesanan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPengiriman(),
            const SizedBox(height: 8),
            _buildServiceItems(),
            const SizedBox(height: 8),
            _buildRingkasan(),
            const SizedBox(height: 8),
            _buildAlamat(),
            if (selectedPaymentMethod != null) ...[
              const SizedBox(height: 8),
              _buildMetodePembayaran(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),

      // --- Tombol bawah ---
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed:
              selectedPaymentMethod != null
                  ? () => _completeOrder(context)
                  : () => _showPaymentOptions(context),
          child: Text(
            selectedPaymentMethod != null
                ? "Selesaikan Pesanan"
                : "Pilih Metode Pembayaran",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Section ---

  Widget _buildPengiriman() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.jumlahBarang} Barang",
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.local_shipping, color: Colors.orange, size: 20),
              SizedBox(width: 6),
              Text(
                "Pengiriman 1–3 Hari",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Service Online",
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: const [
                Icon(Icons.delivery_dining, color: Colors.blue, size: 30),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Estimasi sampai: Maks. Senin, 20 Okt",
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        "Jam 07:00 – 21:00",
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItems() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Layanan ${widget.serviceType == 'cleaning' ? 'Cleaning' : 'Perbaikan'}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    widget.serviceType == 'cleaning'
                        ? Icons.cleaning_services
                        : Icons.build,
                    color: Colors.blue,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item['merek']} ${item['device']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Status: ${item['status'] ?? '-'}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Seri: ${item['seri'] ?? '-'}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (widget.serviceType == 'repair' &&
                            item['part'] != null)
                          Text(
                            "Keluhan: ${item['part']}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        const SizedBox(height: 6),
                        const Text(
                          "1x   Rp 50.000",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasan() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan Pesanan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _summaryRow("Subtotal", "Rp ${widget.jumlahBarang * 50000}"),
          _summaryRow("Diskon", "Rp 0"),
          _summaryRow("Voucher", "Rp 0"),
          _summaryRow("Total ongkos kirim", "Rp 0"),
          const Divider(),
          _summaryRow(
            "Total Belanja",
            "Rp ${widget.jumlahBarang * 50000}",
            isTotal: true,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildAlamat() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DetailAlamatPage()),
        );
        if (result != null) {
          setState(() {
            selectedAddress = result;
          });
        }
      },
      child: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Kirim ke Alamat",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  "Tambahkan Alamat",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(10),
              child:
                  selectedAddress != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${selectedAddress!['nama']} - ${selectedAddress!['hp']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedAddress!['detailAlamat'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          if (selectedAddress!['catatan'] != null &&
                              selectedAddress!['catatan'].isNotEmpty)
                            Text(
                              "Catatan: ${selectedAddress!['catatan']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Atur alamat anda di sini",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.alamat,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Tambahkan catatan untuk memudahkan kurir menemukan lokasimu.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "GPS belum aktif. Aktifkan dulu supaya alamatmu terbaca dengan tepat.",
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodePembayaran() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Metode Pembayaran",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(_getPaymentIcon(selectedPaymentMethod!), color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPaymentMethod!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Text(
                      "Nomor Rekening: 1234567890",
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Metode Pembayaran",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              _paymentItem(Icons.account_balance, "Transfer Bank BCA"),
              _paymentItem(Icons.account_balance_wallet, "Transfer Bank BRI"),
              _paymentItem(
                Icons.account_balance_rounded,
                "Transfer Bank Mandiri",
              ),
              _paymentItem(Icons.payment, "Midtrans Payment"),
              _paymentItem(Icons.payment, "Manual Payment"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _paymentItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () async {
        if (label == "Midtrans Payment") {
          // Close bottom sheet dulu
          Navigator.pop(context);

          // Tampilkan loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            // 🔹 Dapatkan customerId dari session
            String? customerId = await SessionManager.getCustomerId();
            if (customerId == null) {
              // Close loading
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer ID tidak ditemukan. Silakan login ulang.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            await PaymentService.startMidtransPayment(
              context: context,
              orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
              amount: widget.jumlahBarang * 50000,
              customerId: customerId, // 🔹 Tambahkan customerId
              customerName: widget.nama,
              customerEmail: '${widget.nama.replaceAll(' ', '').toLowerCase()}@example.com',
              customerPhone: selectedAddress != null ? selectedAddress!['hp'] ?? '08123456789' : '08123456789',
              itemDetails: widget.items.map((item) => {
                'id': '34GM',
                'price': 50000,
                'quantity': 1,
                'name': 'Service ${item['merek']} ${item['device']}',
              }).toList(),
              onTransactionFinished: (result) {
                // Close loading
                Navigator.of(context, rootNavigator: true).pop();

                // 🔹 Debug: print result details (HANYA status!)
                print('Payment Result - Status: ${result.status}');

                // 🔹 Cek apakah transaksi sukses menggunakan helper method
                if (PaymentService.isTransactionSuccess(result)) {
                  _onPaymentSuccess();
                } else {
                  // Tampilkan pesan error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(PaymentService.getStatusMessage(result)),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            );
          } catch (e) {
            // Close loading jika masih ada
            if (Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          setState(() {
            selectedPaymentMethod = label;
          });
          Navigator.pop(context);
        }
      },
    );
  }

  // Dan update method _onPaymentSuccess:
  void _onPaymentSuccess() async {
    // Get customer ID from session
    String? customerId = await SessionManager.getCustomerId();
    if (customerId != null) {
      // Create payment record in backend
      try {
        await PaymentService.createPayment(
          customerId: customerId,
          amount: widget.jumlahBarang * 50000,
          kodeBarang: null,
        );
        print('Payment record created successfully');
      } catch (e) {
        print('Failed to create payment record: $e');
        // Continue with order completion even if payment record fails
      }
    }

    // Set selected payment method
    setState(() {
      selectedPaymentMethod = "Midtrans Payment";
    });

    // Complete order
    _completeOrder(context);
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case "Transfer Bank BCA":
        return Icons.account_balance;
      case "Transfer Bank BRI":
        return Icons.account_balance_wallet;
      case "Transfer Bank Mandiri":
        return Icons.account_balance_rounded;
      default:
        return Icons.account_balance;
    }
  }

  void _completeOrder(BuildContext context) async {
    // Buat kode antrean baru setiap pesanan selesai
    currentQueueCode = _generateQueueCode(widget.serviceType);

    // Simpan informasi pesanan ke SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('${currentQueueCode}_nama', widget.nama);
    await prefs.setString(
      '${currentQueueCode}_serviceType',
      widget.serviceType,
    );
    await prefs.setString(
      '${currentQueueCode}_device',
      widget.items.isNotEmpty
          ? widget.items[0]['device'] ?? 'Unknown'
          : 'Unknown',
    );
    await prefs.setString(
      '${currentQueueCode}_merek',
      widget.items.isNotEmpty
          ? widget.items[0]['merek'] ?? 'Unknown'
          : 'Unknown',
    );
    await prefs.setString(
      '${currentQueueCode}_seri',
      widget.items.isNotEmpty
          ? widget.items[0]['seri'] ?? 'Unknown'
          : 'Unknown',
    );
    await prefs.setString(
      '${currentQueueCode}_jamMulai',
      DateTime.now().toString(),
    );

    // Debug print untuk memastikan data tersimpan
    print('Data tersimpan untuk kode: $currentQueueCode');
    print('Nama: ${widget.nama}');
    print('Service Type: ${widget.serviceType}');
    print(
      'Device: ${widget.items.isNotEmpty ? widget.items[0]['device'] : 'Unknown'}',
    );
    print(
      'Merek: ${widget.items.isNotEmpty ? widget.items[0]['merek'] : 'Unknown'}',
    );
    print(
      'Seri: ${widget.items.isNotEmpty ? widget.items[0]['seri'] : 'Unknown'}',
    );

    _showSuccessPopup(context, currentQueueCode);
  }

  void _showSuccessPopup(BuildContext context, String queueCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF90CAF9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Pesanan Berhasil",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Tim pick-up kami akan segera sampai,\n"
                            "mohon menunggu selama beberapa menit",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                queueCode, // tampilkan kode antrean dinamis
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Salin kode antrean untuk mengetahui\n"
                            "perkembangan service anda",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ServicePage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Kembali",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: queueCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Kode berhasil disalin"),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Salin Kode",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        TrackingPage(queueCode: queueCode),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text(
                            "Lacak Pesanan",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
