import 'dart:convert';
import 'package:e_service/user_point_data.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  String? scannedResult;
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ==== HEADER + CARD PROFIL DI STACK ====
          Stack(
            clipBehavior: Clip.none,
            children: [
              // HEADER
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Image.asset('assets/image/logo.png', width: 95, height: 30),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.support_agent, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20), // jarak header ke scanner

          // ==== AREA SCANNER ====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(
                            controller: controller,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  final String code = barcode.rawValue!;
                                  setState(() {
                                    scannedResult = code;
                                  });
                                  controller.stop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('QR Terdeteksi: $code')),
                                  );
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (mounted) {
                                      setState(() {
                                        scannedResult = null;
                                      });
                                      controller.start();
                                    }
                                  });
                                  break;
                                }
                              }
                            },
                          ),
                          if (scannedResult == null)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.qr_code_scanner,
                                    size: 80, color: Colors.black38),
                                SizedBox(height: 8),
                                Text(
                                  "Scan untuk mendapatkan poin",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  if (scannedResult != null)
                    Text(
                      "Hasil Scan: $scannedResult",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
