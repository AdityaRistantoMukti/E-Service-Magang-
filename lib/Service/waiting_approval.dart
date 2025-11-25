import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'tracking_driver.dart';
import '../api_services/api_service.dart';
import '../Others/session_manager.dart';

class WaitingApprovalPage extends StatefulWidget {
  final String? transKode; // Optional, if not provided, will fetch latest

  const WaitingApprovalPage({
    super.key,
    this.transKode,
  });

  @override
  State<WaitingApprovalPage> createState() => _WaitingApprovalPageState();
}

class _WaitingApprovalPageState extends State<WaitingApprovalPage> {
  bool isApproved = false;
  String transKode = 'Loading...';
  List<dynamic> orderList = [];
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    if (widget.transKode != null) {
      transKode = widget.transKode!;
      _loadOrderDetails();
      _startStatusCheck();
    } else {
      _fetchLatestTransKode().then((_) {
        _loadOrderDetails();
        _startStatusCheck();
      });
    }
  }

  Future<void> _fetchLatestTransKode() async {
    try {
      // Get customer kode from session
      String? cosKode = await SessionManager.getCustomerId();

      // Get all transactions for this customer
      final allTransaksi = await ApiService.getTransaksi();

      if (allTransaksi is List) {
        final customerTransaksi = allTransaksi
            .where((o) => o['cos_kode'].toString() == cosKode)
            .toList();

        customerTransaksi.sort(
          (a, b) => DateTime.parse(b['trans_tanggal'] ?? DateTime.now().toString())
              .compareTo(DateTime.parse(a['trans_tanggal'] ?? DateTime.now().toString())),
        );

        if (customerTransaksi.isNotEmpty) {
          setState(() {
            transKode = customerTransaksi.first['trans_kode'] ?? 'No trans_kode';
          });
        } else {
          setState(() {
            transKode = 'No transactions found';
          });
        }
      } else {
        setState(() {
          transKode = 'Invalid response format';
        });
      }
    } catch (e) {
      print('Error fetching latest trans_kode: $e');
      setState(() {
        transKode = 'Error loading trans_kode';
      });
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    if (transKode.isEmpty) return;
    try {
      final orders = await ApiService.getOrderListByTransKode(transKode);
      setState(() {
        orderList = orders;
      });
    } catch (e) {
      print('Error loading order details: $e');
      // Don't throw error, just log it and continue
    }
  }

  void _startStatusCheck() {
    if (transKode.isEmpty) return;
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final orders = await ApiService.getOrderListByTransKode(transKode);
        if (orders.isNotEmpty) {
          final status = orders.first['trans_status']?.toString().toLowerCase() ?? 'pending';

          if (status == 'confirm') {
            setState(() {
              isApproved = true;
            });
            _statusCheckTimer?.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackingPage(queueCode: transKode),
                ),
              );
            });
          }
        }
      } catch (e) {
        print('Error checking status: $e');
        // Don't throw error, just log it and continue
      }
    });
  }

  void _approveOrder() async {
    setState(() {
      isApproved = true;
    });
    // Simulate approval process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingPage(queueCode: transKode),
        ),
      );
    });
  }

  void _copyTransKode() {
    Clipboard.setData(ClipboardData(text: transKode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trans Kode berhasil disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0041c3),
        title: const Text(
          "Menunggu Persetujuan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.hourglass_empty,
                size: 80,
                color: isApproved ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 20),
              Text(
                isApproved ? "Pesanan Disetujui!" : "Menunggu Persetujuan Admin",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (!isApproved)
                Column(
                  children: [
                    Text(
                      'Trans Kode: $transKode',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _copyTransKode,
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text('Salin Trans Kode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              Text(
                isApproved
                    ? "Sedang mengarahkan ke halaman tracking..."
                    : "Pesanan Anda sedang dalam proses persetujuan. Mohon tunggu sebentar.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (orderList.isNotEmpty && !isApproved)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Device:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...orderList.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${order['device'] ?? 'Device'} - ${order['merek'] ?? 'Merek'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              'Qty: ${order['quantity'] ?? 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
