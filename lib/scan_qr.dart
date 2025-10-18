import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'notifikasi.dart';

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
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ==== CARD PROFIL FLOATING ====
              Positioned(
                left: 16,
                right: 16,
                bottom: -150, 
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.person, size: 50, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      const Text('Udin',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Id 202234001',
                          style:
                              TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Poin',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 10),
                          const Text('25',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Image.asset('assets/image/coin.png',
                              width: 16, height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 140), 

          // ==== AREA SCANNER ====
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _scanFromGallery,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Scan dari Galeri'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final BarcodeCapture? capture = await controller.analyzeImage(image.path);

        if (capture != null && capture.barcodes.isNotEmpty) {
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null) {
              final String code = barcode.rawValue!;
              setState(() {
                scannedResult = code;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('QR dari Galeri Terdeteksi: $code')),
              );
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    scannedResult = null;
                  });
                }
              });
              break;
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada QR code yang terdeteksi di gambar')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
