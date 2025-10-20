import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DetailAlamatPage extends StatefulWidget {
  const DetailAlamatPage({super.key});

  @override
  State<DetailAlamatPage> createState() => _DetailAlamatPageState();
}

class _DetailAlamatPageState extends State<DetailAlamatPage> {
  final TextEditingController labelController =
      TextEditingController(text: "perguruan tinggi");
  final TextEditingController detailController =
      TextEditingController(text: "Universitas Bina Insani lantai 1");
  final TextEditingController catatanController = TextEditingController();
  final TextEditingController namaController =
      TextEditingController(text: "Adit");
  final TextEditingController hpController =
      TextEditingController(text: "081292303471");

  bool jadikanUtama = false;
  bool _loading = true;
  bool _mapMoving = false;

  String _alamat = "Mendeteksi lokasi...";
  LatLng _currentLatLng = const LatLng(-6.200000, 106.816666); // Jakarta default
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _alamat = "GPS tidak aktif.";
        _loading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _alamat = "Izin lokasi ditolak.";
          _loading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _alamat = "Izin lokasi permanen ditolak.";
        _loading = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _updateAddressFromLatLng(
        LatLng(position.latitude, position.longitude),
        moveMap: true);
  }

  Future<void> _updateAddressFromLatLng(LatLng latLng,
      {bool moveMap = false}) async {
    setState(() {
      _currentLatLng = latLng;
      _loading = true;
    });

    try {
      final placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _alamat =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
        detailController.text = _alamat;
      }
    } catch (_) {
      _alamat = "Gagal mendapatkan alamat.";
    }

    if (moveMap) {
      _mapController.move(latLng, 17);
    }

    setState(() => _loading = false);
  }

  void _pusatkanLokasi() {
    _mapController.move(_currentLatLng, 17);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text("Detail Alamat",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // === MAP ===
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLatLng,
                        initialZoom: 17,
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture) {
                            _mapMoving = true;
                          }
                        },
                        onMapEvent: (event) {
                          if (event is MapEventMoveEnd && _mapMoving) {
                            _updateAddressFromLatLng(_mapController.camera.center);
                            _mapMoving = false;
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.azzahra.e_service',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLatLng,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_pin,
                                  color: Colors.redAccent, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Tombol pusatkan lokasi
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FloatingActionButton(
                        heroTag: "center",
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _pusatkanLokasi,
                        child: const Icon(Icons.my_location,
                            color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              ),

              // === ALAMAT ===
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.redAccent, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_alamat,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blue),
                      onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
              ),

              // === FORM ===
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField("Label*", labelController),
                        _buildTextField("Detail Alamat*", detailController),
                        _buildTextField(
                            "Catatan Alamat (Tidak Wajib)", catatanController),
                        _buildTextField("Nama Penerima*", namaController),
                        _buildTextField("No. Handphone Penerima*", hpController,
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Jadikan sebagai alamat utama",
                                style: TextStyle(fontSize: 14)),
                            Switch(
                              value: jadikanUtama,
                              onChanged: (v) =>
                                  setState(() => jadikanUtama = v),
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Alamat berhasil disimpan ✅"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Simpan",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Overlay loading
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Colors.black26, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
