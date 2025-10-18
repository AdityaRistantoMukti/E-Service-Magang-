import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'service.dart';
import 'shop.dart';
import 'promo.dart';
import 'profile.dart';
import 'progres_service.dart';
import 'notifikasi.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  int currentIndex = 2; // posisi default: Home

  GoogleMapController? _mapController;

  // Titik awal & tujuan (contoh data)
  final LatLng _pickupPoint = const LatLng(-6.914744, 107.609810); // Bandung
  final LatLng _destinationPoint = const LatLng(-6.917464, 107.619123);

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setMarkers();
  }

  void _setMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId("pickup"),
        position: _pickupPoint,
        infoWindow: const InfoWindow(title: "Lokasi Penjemputan"),
      ),
      Marker(
        markerId: const MarkerId("destination"),
        position: _destinationPoint,
        infoWindow: const InfoWindow(title: "Tujuan Servis"),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: null,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ServicePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MarketplacePage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TukarPoinPage()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
        backgroundColor: Colors.blue,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Beli',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: currentIndex == 3 ? Image.asset('assets/image/promo.png', width: 24, height: 24) : Opacity(opacity: 0.6, child: Image.asset('assets/image/promo.png', width: 24, height: 24)),
            label: 'Promo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📄 Informasi Detail
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("Nama", "Udin", "Jam Mulai", "10.00"),
                  const SizedBox(height: 8),
                  _infoRow("Device", "Laptop", "Jam Selesai", "-"),
                  const SizedBox(height: 8),
                  _infoRow("Merek", "Asus", "", ""),
                  const SizedBox(height: 8),
                  _infoRow("Seri", "xxxxxxxxxx", "", ""),
                  const SizedBox(height: 12),
                  Text("Jenis Service :", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chipService("Upgrade RAM"),
                      _chipService("Upgrade SSD"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🗺️ Google Maps (Real)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _pickupPoint,
                        zoom: 14,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      onMapCreated: (controller) => _mapController = controller,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔄 Status Tracking
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statusBox(
                        color: Colors.green[100]!,
                        icon: Icons.check_circle_outline,
                        label: 'Menerima pesanan',
                      ),
                      _statusBox(
                        color: Colors.yellow[100]!,
                        icon: Icons.timelapse,
                        label: 'Menuju lokasi',
                      ),
                      _statusBox(
                        color: Colors.red[100]!,
                        icon: Icons.schedule_outlined,
                        label: 'Pick-up barang',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _legendDot(Colors.green, "Selesai"),
                          const SizedBox(width: 6),
                          _legendDot(Colors.yellow, "Proses"),
                          const SizedBox(width: 6),
                          _legendDot(Colors.red, "Menunggu"),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CekProgresServicePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          'Status Service',
                          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                "$label1 : ",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Text(value1, style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ],
          ),
        ),
        if (label2.isNotEmpty)
          Expanded(
            child: Row(
              children: [
                Text(
                  "$label2 : ",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(value2, style: GoogleFonts.poppins(fontSize: 13)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chipService(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }

  Widget _statusBox({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }
}
