import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'pick_lokasi.dart';

class DetailAlamatPage extends StatefulWidget {
  const DetailAlamatPage({super.key});

  @override
  State<DetailAlamatPage> createState() => _DetailAlamatPageState();
}

class _DetailAlamatPageState extends State<DetailAlamatPage>
    with WidgetsBindingObserver {
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

  String _alamat = "Mendeteksi lokasi...";
  String _detailAlamat = "";
  bool _loading = true;
  bool _waitingForSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Deteksi kalau user kembali dari settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      // Setelah user kembali dari Settings, refresh lokasi
      _waitingForSettings = false;
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _loading = true;
    });

    // Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _alamat = "Layanan lokasi tidak aktif.";
        _loading = false;
      });

      // Tampilkan dialog untuk menyalakan lokasi
      _showEnableLocationDialog();
      return;
    }

    // Cek izin lokasi
    permission = await Geolocator.checkPermission();
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
        _alamat = "Izin lokasi ditolak permanen.";
        _loading = false;
      });
      _showPermissionDeniedDialog();
      return;
    }

    // Ambil lokasi sekarang
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Ubah koordinat ke alamat (reverse geocoding)
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        _alamat =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        _detailAlamat =
            "Kode Pos: ${place.postalCode ?? '-'}\nWilayah: ${place.subAdministrativeArea ?? '-'}\nKoordinat: ${position.latitude}, ${position.longitude}";
        detailController.text = _alamat;
        _loading = false;
      });
    }
  }

  // === Dialog jika layanan lokasi mati ===
  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aktifkan Lokasi"),
        content: const Text(
            "Layanan GPS tidak aktif. Aktifkan lokasi agar aplikasi dapat mendeteksi alamat Anda."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _waitingForSettings = true;
              await Geolocator.openLocationSettings();
            },
            child: const Text(
              "Aktifkan",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // === Dialog jika izin lokasi ditolak permanen ===
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Izin Lokasi Diperlukan"),
        content: const Text(
            "Aplikasi membutuhkan izin lokasi. Silakan aktifkan izin lokasi di pengaturan aplikasi."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _waitingForSettings = true;
              await Geolocator.openAppSettings();
            },
            child: const Text(
              "Buka Pengaturan",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text(
          "Detail Alamat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // === Bagian Lokasi Otomatis ===
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.redAccent, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Lokasi Saat Ini",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                _alamat,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _detailAlamat,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                          onPressed: _getCurrentLocation,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // === FORM INPUT ===
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField("Label*", labelController,
                            hint: "Tulis Rumah, Kos, Kantor dll",
                            maxLength: 30),
                        _buildTextField("Detail Alamat*", detailController,
                            hint:
                                "Cth: no. rumah/jalan/unit (wajib ada angka)",
                            maxLength: 100),
                        _buildTextField(
                            "Catatan Alamat (Tidak Wajib)", catatanController,
                            hint: "Cth: Rumah dekat pos kamling", maxLength: 100),
                        _buildTextField("Nama Penerima*", namaController,
                            maxLength: 30),
                        _buildTextField("No. Handphone Penerima*", hpController,
                            keyboardType: TextInputType.phone, maxLength: 15),
                        const SizedBox(height: 10),

                        // === Switch Jadikan utama ===
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Jadikan sebagai alamat utama",
                                style: TextStyle(fontSize: 14)),
                            Switch(
                              value: jadikanUtama,
                              onChanged: (v) {
                                setState(() => jadikanUtama = v);
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === Tombol Simpan ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? hint,
      int? maxLength,
      TextInputType keyboardType = TextInputType.text}) {
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
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              counterText: "",
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
