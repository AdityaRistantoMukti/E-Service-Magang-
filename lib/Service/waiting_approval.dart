import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'tracking_driver.dart';

class WaitingApprovalPage extends StatefulWidget {
  final String serviceType;
  final String nama;
  final int jumlahBarang;
  final List<Map<String, String?>> items;
  final String alamat;

  const WaitingApprovalPage({
    super.key,
    required this.serviceType,
    required this.nama,
    required this.jumlahBarang,
    required this.items,
    required this.alamat,
  });

  @override
  State<WaitingApprovalPage> createState() => _WaitingApprovalPageState();
}

class _WaitingApprovalPageState extends State<WaitingApprovalPage> {
  bool isApproved = false;
  late String transKode;

  @override
  void initState() {
    super.initState();
    transKode = 'TTS${DateTime.now().millisecondsSinceEpoch}-${widget.serviceType}';
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
        backgroundColor: Colors.blue,
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
              const SizedBox(height: 30),
              if (!isApproved)
                ElevatedButton(
                  onPressed: _approveOrder, // For demo purposes
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  child: const Text(
                    "Approve (Demo)",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
