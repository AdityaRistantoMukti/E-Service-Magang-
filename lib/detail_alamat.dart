import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'pick_lokasi.dart';

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
  late GoogleMapController mapController;

  LatLng _lokasi = const LatLng(-6.247726, 107.000874); // contoh lokasi
  String _alamat = "Bina Insani University, jl raya rawa panjang No.6, RT.001/RW.003, Sepanjang Jaya, Kec. Rawalumbu, Kota Bks, Jawa Barat 17114, Indonesia";

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === Map Lokasi ===
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 180,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _lokasi,
                        zoom: 17,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("lokasi"),
                          position: _lokasi,
                        )
                      },
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Alamat lengkap (Berdasarkan titik lokasi)",
                            style: TextStyle(
                                fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(
                          _alamat,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PilihLokasiPage(),
                            ),
                          );
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              _lokasi = result['latlng'];
                              _alamat = result['address'];
                              detailController.text = _alamat;
                            });
                            mapController.animateCamera(
                              CameraUpdate.newLatLng(_lokasi),
                            );
                          }
                        },
                        icon: const Icon(Icons.location_on, color: Colors.blue),
                        label: const Text(
                          "Ubah Titik Lokasi",
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // === FORM INPUT ===
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField("Label*", labelController,
                      hint: "Tulis Rumah, Kos, Kantor dll", maxLength: 30),
                  _buildTextField("Detail Alamat*", detailController,
                      hint: "Cth: no. rumah/jalan/unit (wajib ada angka)",
                      maxLength: 100),
                  _buildTextField("Catatan Alamat (Tidak Wajib)",
                      catatanController,
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
