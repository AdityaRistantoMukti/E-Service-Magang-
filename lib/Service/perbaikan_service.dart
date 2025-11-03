import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/Service/detail_alamat.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'waiting_approval.dart';

  class PerbaikanServicePage extends StatefulWidget {
    const PerbaikanServicePage({super.key});

    @override
    State<PerbaikanServicePage> createState() => _PerbaikanServicePageState();
  }

  class _PerbaikanServicePageState extends State<PerbaikanServicePage> {
    int currentIndex = 0;

    final TextEditingController namaController = TextEditingController();
    Map<String, dynamic>? selectedAddress;

    bool _isSuccess(Map<String, dynamic>? r) {
      if (r == null) return false;
      if (r.containsKey('success')) {
        final v = r['success'];
        return (v is bool) ? v : (v.toString().toLowerCase() == 'true');
      }
      if (r.containsKey('status')) {
        final v = r['status'];
        return (v is bool) ? v : (v.toString().toLowerCase() == 'true');
      }
      return false;
    }

    int jumlahBarang = 1;
    List<TextEditingController> seriControllers = [];
    List<TextEditingController> partControllers = [];
    List<TextEditingController> emailControllers = []; // Tambahkan untuk email
    List<String?> selectedMereks = [];
    List<String?> selectedDevices = [];
    List<String?> selectedStatuses = [];

    final List<String> merekOptions = ['Asus', 'Dell', 'HP', 'Lenovo', 'Apple', 'Samsung', 'Sony', 'Toshiba'];
    final List<String> deviceOptions = ['Laptop', 'Desktop', 'Tablet', 'Smartphone', 'Printer', 'Monitor', 'Keyboard', 'Mouse'];
    final List<String> statusOptions = ['CID', 'IW (Masih Garansi)', 'OOW (Tidak Garansi)'];

    @override
    void initState() {
      super.initState();
      _initializeItemFields();
      _loadUserData();
    }

    void _loadUserData() async {
      final session = await SessionManager.getUserSession();
      final userName = session['name'] as String?;
      if (userName != null) {
        setState(() {
          namaController.text = userName;
        });
      }
    }

    void _initializeItemFields() {
      seriControllers = List.generate(jumlahBarang, (_) => TextEditingController());
      partControllers = List.generate(jumlahBarang, (_) => TextEditingController());
      emailControllers = List.generate(jumlahBarang, (_) => TextEditingController()); // Tambahkan emailControllers
      selectedMereks = List.filled(jumlahBarang, null);
      selectedDevices = List.filled(jumlahBarang, null);
      selectedStatuses = List.filled(jumlahBarang, null);
    }

    void _updateJumlahBarang(int newJumlah) {
      setState(() {
        jumlahBarang = newJumlah;
        _initializeItemFields();
      });
    }

    // Fungsi untuk mendapatkan email lengkap
    String _getFullEmail(int index) {
      String username = emailControllers[index].text.trim();
      if (username.isEmpty) return '';
      return '$username@gmail.com';
    }

    @override
    Widget build(BuildContext context) {
      if (selectedStatuses.length != jumlahBarang ||
          selectedMereks.length != jumlahBarang ||
          selectedDevices.length != jumlahBarang ||
          seriControllers.length != jumlahBarang ||
          partControllers.length != jumlahBarang ||
          emailControllers.length != jumlahBarang) { // Tambahkan emailControllers
        _initializeItemFields();
      }

      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ==== HEADER ====
            Container(
              height: 130,
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Image.asset('assets/image/logo.png', width: 130, height: 40),
                  const Spacer(),                
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

            // ==== KONTEN ====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, bottom: 100),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _inputField("Nama", namaController, readOnly: true),
                          const SizedBox(height: 12),
                          _jumlahBarangField(),
                          const SizedBox(height: 12),
                          _buildAlamat(),
                          const SizedBox(height: 12),

                          // ==== DAFTAR BARANG ====
                          ...List.generate(jumlahBarang, (index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Barang ${index + 1}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _dropdownField("Merek", selectedMereks[index], merekOptions, (value) {
                                    setState(() {
                                      selectedMereks[index] = value;
                                    });
                                  }),
                                  const SizedBox(height: 10),
                                  _dropdownField("Device", selectedDevices[index], deviceOptions, (value) {
                                    setState(() {
                                      selectedDevices[index] = value;
                                    });
                                  }),
                                  const SizedBox(height: 10),
                                  _dropdownField("Status", selectedStatuses[index], statusOptions, (value) {
                                    setState(() {
                                      selectedStatuses[index] = value;
                                    });
                                  }),
                                  const SizedBox(height: 10),
                                  _inputField("Seri", seriControllers[index]),
                                  const SizedBox(height: 10),
                                  _inputField("Keterangan Keluhan", partControllers[index]),
                                  // Kondisi untuk menampilkan field email
                                  if (selectedStatuses[index] == "IW (Masih Garansi)" &&
                                      selectedMereks[index] == "Lenovo") ...[
                                    const SizedBox(height: 10),
                                    _emailField("Email *", emailControllers[index]), // Gunakan _emailField khusus
                                  ],
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                // Validation
                                if (namaController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nama wajib diisi dan tidak boleh kosong')),
                                  );
                                  return;
                                }
                                if (selectedAddress == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Alamat pengiriman wajib dipilih')),
                                  );
                                  return;
                                }
                                for (int i = 0; i < jumlahBarang; i++) {
                                  if (selectedMereks[i] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Merek wajib dipilih')),
                                    );
                                    return;
                                  }
                                  if (selectedDevices[i] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Device wajib dipilih')),
                                    );
                                    return;
                                  }
                                  if (selectedStatuses[i] == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Status wajib dipilih')),
                                    );
                                    return;
                                  }
                                  if (seriControllers[i].text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Seri wajib diisi dan tidak boleh kosong')),
                                    );
                                    return;
                                  }
                                  if (partControllers[i].text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Keterangan Keluhan wajib diisi dan tidak boleh kosong')),
                                    );
                                    return;
                                  }
                                  // Validasi email jika kondisi terpenuhi
                                  if (selectedStatuses[i] == "IW (Masih Garansi)" &&
                                      selectedMereks[i] == "Lenovo") {
                                    String fullEmail = _getFullEmail(i);
                                    if (fullEmail.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Email wajib diisi',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    // Validasi format email lengkap
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(fullEmail)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Format email tidak valid',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                }
                                // If all validations pass
                                List<Map<String, String?>> items = [];
                                for (int i = 0; i < jumlahBarang; i++) {
                                  items.add({
                                    'merek': selectedMereks[i],
                                    'device': selectedDevices[i],
                                    'status_garansi': selectedStatuses[i],
                                    'seri': seriControllers[i].text,
                                    'ket_keluhan': partControllers[i].text,
                                    'email': (selectedStatuses[i] == "IW (Masih Garansi)" &&
                                            selectedMereks[i] == "Lenovo")
                                        ? _getFullEmail(i)
                                        : null,
                                  });
                                }

                              // Send data to API: create order_list in azza database
                              try {
                                String cosKode = await SessionManager.getCustomerId() ?? '';
                                String transTanggal = DateTime.now().toIso8601String().split('T')[0];

                                // Create order_list for each item
                                bool orderSuccess = true;
                                Map<String, dynamic>? lastOrderResponse;
                                for (int i = 0; i < items.length; i++) {
                                  var item = items[i];

                                  // Create order_list for each item
                                  Map<String, dynamic> orderData = {
                                    'cos_kode': cosKode,
                                    'trans_total': 0.0,
                                    'trans_discount': 0.0,
                                    'trans_tanggal': transTanggal,
                                    'trans_status': 'pending',
                                    'merek': item['merek'],
                                    'device': item['device'],
                                    'status_garansi': item['status_garansi'],
                                    'seri': item['seri'],
                                    'ket_keluhan': item['ket_keluhan'],
                                    'email': item['email'] ?? 'example@gmail.com',
                                    'alamat': selectedAddress!['alamat'],
                                  };
                                  print('Order data: $orderData'); // Debug: check order data
                                  try {
                                    Map<String, dynamic> orderResponse = await ApiService.createOrderList(orderData);
                                    print('Order response: $orderResponse'); // Debug: check order response
                                    lastOrderResponse = orderResponse;
                                    if (!_isSuccess(orderResponse)) {
                                      orderSuccess = false;
                                      break;
                                    }
                                  } catch (e) {
                                    print('Error creating order_list: $e'); // Debug: print the error
                                    orderSuccess = false;
                                    break;
                                  }
                                }

                                if (orderSuccess && lastOrderResponse != null) {
                                  // Get trans_kode from the last successful order response
                                  String transKode = lastOrderResponse['data']['trans_kode'];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WaitingApprovalPage(transKode: transKode),
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Gagal'),
                                        content: Text('Gagal membuat pesanan'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Gagal'),
                                      content: Text('Gagal membuat pesanan: $e'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Pesan",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
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

        // ==== BOTTOM NAV ====
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServicePage()));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MarketplacePage()));
            } else if (index == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
            } else if (index == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TukarPoinPage()));
            } else if (index == 4) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            }
          },
          backgroundColor: const Color(0xFF1976D2),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: 'Service'),
            const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Beli'),
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: currentIndex == 3
                  ? Image.asset('assets/image/promo.png', width: 24, height: 24)
                  : Opacity(opacity: 0.6, child: Image.asset('assets/image/promo.png', width: 24, height: 24)),
              label: 'Promo',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      );
    }

    // ==== WIDGET INPUT ====
    Widget _inputField(String label, TextEditingController controller, {bool readOnly = false}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1976D2)),
              ),
            ),
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      );
    }

    Widget _buildAlamat() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kirim Ke Alamat",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedAddress != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedAddress!['alamat'] ?? '',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Detail: ${selectedAddress!['detailAlamat'] ?? ''}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Penerima: ${selectedAddress!['nama'] ?? ''} (${selectedAddress!['hp'] ?? ''})",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
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
                      child: const Text(
                        "Ubah Alamat",
                        style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    "Belum ada alamat yang dipilih",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Pilih Alamat",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Widget khusus untuk email dengan keyboard email
    Widget _emailField(String label, TextEditingController controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress, // Keyboard email untuk bantuan format
            autofillHints: [AutofillHints.email], // Bantuan autofill email
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1976D2)),
              ),
              hintText: 'Masukkan email Gmail',
            ),
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      );
    }

    Widget _dropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: selectedValue,
              hint: const Text('Pilih...', style: TextStyle(color: Colors.black54)),
              isExpanded: true,
              underline: const SizedBox(),
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      );
    }

    Widget _jumlahBarangField() {
      return Row(
        children: [
          const Text("Jumlah Barang :", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18, color: Colors.black),
                  onPressed: jumlahBarang > 1 ? () => _updateJumlahBarang(jumlahBarang - 1) : null,
                ),
                Text(jumlahBarang.toString(), style: const TextStyle(fontSize: 16, color: Colors.black)),
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  onPressed: jumlahBarang < 10 ? () => _updateJumlahBarang(jumlahBarang + 1) : null,
                ),
              ],
            ),
          ),
        ],
      );
    }


  }
