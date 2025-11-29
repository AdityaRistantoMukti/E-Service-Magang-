import 'dart:convert';
import 'package:azza_service/Service/detail_alamat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'struck_pesanan.dart';
import 'payment_confirmation.dart';
import 'riwayat.dart';
import 'package:image_picker/image_picker.dart';
import '../api_services/payment_service.dart';
import '../api_services/api_service.dart';
import '../Others/session_manager.dart';
import '../Others/user_point_data.dart';
import '../models/promo_model.dart';
import '../models/voucher_model.dart';
import '../config/api_config.dart';
import 'custom_dialog.dart';
import '../main.dart';
import '../Others/midtrans_webview.dart';

class CheckoutPoinPage extends StatefulWidget {
  final Map<String, dynamic> produk;
  const CheckoutPoinPage({
    super.key,
    required this.produk,
  });

  @override
  State<CheckoutPoinPage> createState() => _CheckoutPoinPageState();
}

class _CheckoutPoinPageState extends State<CheckoutPoinPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  late BuildContext _pageContext;
  late BuildContext pageContext;
  String? selectedPaymentMethod;
  String? selectedShipping;
  String? selectedBank;
  Map<String, dynamic>? selectedAddress;
  Map<String, dynamic>? userData;
  bool useVoucher = false;
  String? selectedVoucher;
  String? selectedEwallet;
  late String namaProduk;
  late String deskripsi;
  String gambarUrl = '';
  List<Promo> promoList = [];
  bool isPromoLoaded = false;
  List<UserVoucher> userVouchers = [];
  bool isUserVouchersLoaded = false;
  double? hargaAsli;

  // Inisialisasi quantity
  late int quantity;

  // Shipping data
  double? customerLat;
  double? customerLng;
  double shippingCost = 0.0;
  double distanceKm = 0.0;
  bool isLoadingShipping = false;
  bool isCalculatingShipping = false;

  // List voucher
  final List<Map<String, dynamic>> availableVouchers = [
    {
      'code': 'DISKON10',
      'name': 'Diskon 10%',
      'description': 'Potongan 10% untuk semua produk',
      'discount': 0.10,
      'minPurchase': 50000,
    },
    {
      'code': 'DISKON20',
      'name': 'Diskon 20%',
      'description': 'Potongan 20% untuk pembelian min Rp 100.000',
      'discount': 0.20,
      'minPurchase': 100000,
    },
    {
      'code': 'GRATISONGKIR',
      'name': 'Gratis Ongkir',
      'description': 'Gratis ongkos kirim untuk semua ekspedisi',
      'discount': 0.0,
      'minPurchase': 0,
      'freeShipping': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    namaProduk = widget.produk['nama_produk']?.toString() ?? 'Produk Tidak Dikenal';
    deskripsi = widget.produk['deskripsi']?.toString() ?? 'Deskripsi tidak tersedia';
    gambarUrl = getFirstImageUrl(widget.produk['gambar']);

    // Initialize quantity dari produk, default 1 jika tidak ada
    quantity = widget.produk['quantity'] ?? 1;

    _fetchPromo();
    _fetchUserVouchers();
    _fetchHargaAsli();
    _getCurrentLocation();
    _loadUserData();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          customerLat = position.latitude;
          customerLng = position.longitude;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // Calculate shipping cost
  Future<void> _calculateShippingCost() async {
    if (customerLat == null || customerLng == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_off,
            color: Colors.orange,
            size: 24,
          ),
        ),
        title: 'Lokasi Tidak Ditemukan',
        content: const Text('Lokasi belum terdeteksi. Mohon aktifkan GPS.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    setState(() {
      isCalculatingShipping = true;
    });

    try {
      final response = await ApiService.estimateShipping(
        customerLat: customerLat!,
        customerLng: customerLng!,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            shippingCost = double.tryParse(data['shipping_cost']?.toString() ?? '0') ?? 0.0;
            distanceKm = double.tryParse(data['distance_km']?.toString() ?? '0') ?? 0.0;
            isCalculatingShipping = false;
          });
        }

        // Show success message
        if (mounted) {
          CustomDialog.show(
            context: context,
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            title: 'Berhasil',
            content: Text('Ongkir berhasil dihitung: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(shippingCost)}'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }
      } else {
        throw Exception('Gagal menghitung ongkir');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCalculatingShipping = false;
        });
        CustomDialog.show(
          context: context,
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 24,
            ),
          ),
          title: 'Error',
          content: Text('Gagal menghitung ongkir: $e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      }
    }
  }

  Future<void> _fetchHargaAsli() async {
    String kodeBarang = widget.produk['kode_barang']?.toString() ?? '';
    if (kodeBarang.isNotEmpty) {
      try {
        final produkList = await ApiService.getProduk();
        final produk = produkList.firstWhere(
          (p) => p['kode_barang']?.toString() == kodeBarang,
          orElse: () => <String, dynamic>{},
        );
        if (produk.isNotEmpty) {
          if (mounted) {
            setState(() {
              hargaAsli = (double.tryParse(produk['harga']?.toString() ?? '0') ?? 0.0) * 10;
            });
          }
        }
      } catch (e) {
        debugPrint("Error fetching harga asli: $e");
      }
    }
  }

  Future<void> _loadUserData() async {
    final session = await SessionManager.getUserSession();
    final userId = session['id'] as String?;
    if (userId != null) {
      try {
        final data = await ApiService.getCostomerById(userId);
        if (mounted) {
          setState(() {
            userData = data;
            // Auto-fill address if cos_alamat exists and no address selected
            if (selectedAddress == null && data['cos_alamat'] != null && data['cos_alamat'].isNotEmpty) {
              selectedAddress = {
                'alamat': data['cos_alamat'],
                'detailAlamat': data['cos_alamat'],
                'nama': data['cos_nama'] ?? '',
                'hp': data['cos_hp'] ?? '',
                'latitude': 0.0,
                'longitude': 0.0,
              };
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<void> _fetchPromo() async {
    try {
      final response = await ApiService.getPromo();
      if (mounted) {
        setState(() {
          promoList = response.map<Promo>((json) => Promo.fromJson(json)).toList();
          isPromoLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isPromoLoaded = true;
        });
      }
      debugPrint("Error loading promo: $e");
    }
  }

  Future<void> _fetchUserVouchers() async {
    try {
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString();
      if (customerId != null) {
        final response = await ApiService.getUserVouchers(customerId);
        if (mounted) {
          setState(() {
            userVouchers = response.map<UserVoucher>((json) => UserVoucher.fromJson(json)).toList();
            isUserVouchersLoaded = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isUserVouchersLoaded = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUserVouchersLoaded = true;
        });
      }
      debugPrint("Error loading user vouchers: $e");
    }
  }

  bool _isProductInPromo() {
    if (!isPromoLoaded || promoList.isEmpty) return false;
    String kodeBarang = widget.produk['kode_barang']?.toString() ?? '';
    return promoList.any((promo) => promo.kodeBarang == kodeBarang);
  }

  String getFirstImageUrl(dynamic gambarField) {
    if (gambarField == null) return '';

    String gambarString = gambarField.toString().trim();

    if (gambarString.startsWith('http')) {
      return gambarString;
    }

    List<String> paths;
    if (gambarString.contains(',')) {
      paths = gambarString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else {
      paths = [gambarString];
    }

    if (paths.isEmpty) return '';

    String cleanPath = _cleanImagePath(paths.first);
    if (cleanPath.isEmpty) return '';

    String baseUrl = ApiConfig.storageBaseUrl;

    if (!cleanPath.startsWith('http')) {
      cleanPath = 'assets/image/$cleanPath';
    }

    String imageUrl = cleanPath.startsWith('http') ? cleanPath : '$baseUrl$cleanPath';

    return imageUrl;
  }

  String _cleanImagePath(String path) {
    path = path.trim();

    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    path = path.replaceAll(ApiConfig.storageBaseUrl, '');

    return path;
  }

  double _getTotalHarga() {
    double hargaPerItem = (double.tryParse(widget.produk['harga']?.toString() ?? '0') ?? 0.0) * 10;
    return hargaPerItem * quantity;
  }

  double _getVoucherDiscount() {
    if (!useVoucher || selectedVoucher == null || !isUserVouchersLoaded) return 0.0;

    final userVoucher = userVouchers.firstWhere(
      (uv) => uv.voucher?.voucherCode == selectedVoucher && uv.isAvailable,
      orElse: () => UserVoucher(id: 0, idCostomer: '', voucherId: 0, claimedDate: DateTime.now(), used: 'yes'),
    );

    if (userVoucher.voucher == null) return 0.0;

    double totalHarga = _getTotalHarga();

    return totalHarga * (userVoucher.voucher!.discountPercent / 100);
  }

  bool _hasVoucherFreeShipping() {
    return false;
  }

  double _getFinalShippingCost() {
    if (_hasVoucherFreeShipping()) {
      return 0.0;
    }
    return shippingCost;
  }

  String _getEstimasiPengiriman() {
    if (distanceKm == 0 || selectedShipping == null) {
      return "Pilih lokasi & ekspedisi";
    }

    if (distanceKm <= 5) {
      return "Pengiriman 1 Hari";
    } else if (distanceKm <= 15) {
      return "Pengiriman 1-2 Hari";
    } else if (distanceKm <= 30) {
      return "Pengiriman 2-3 Hari";
    } else {
      return "Pengiriman 3-5 Hari";
    }
  }

  String _getZonaDescription() {
    if (distanceKm == 0) return '';

    if (distanceKm <= 5) {
      return "Zona Dekat - Rp 5.000 flat";
    } else if (distanceKm <= 20) {
      return "Zona Menengah - Rp 2.000/km";
    } else {
      return "Zona Jauh - Rp 1.500/km";
    }
  }

  String _getEstimasiSampai() {
    if (distanceKm == 0 || selectedShipping == null) {
      return "Estimasi akan muncul setelah memilih lokasi";
    }

    DateTime now = DateTime.now();
    DateTime estimatedDate;

    if (distanceKm <= 5) {
      estimatedDate = now.add(const Duration(days: 1));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Besok)";
    } else if (distanceKm <= 15) {
      estimatedDate = now.add(const Duration(days: 2));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 2 hari)";
    } else if (distanceKm <= 30) {
      estimatedDate = now.add(const Duration(days: 3));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 3 hari)";
    } else {
      estimatedDate = now.add(const Duration(days: 5));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 5 hari)";
    }
  }

  String _getJamOperasional() {
    if (distanceKm == 0) {
      return "Pilih lokasi untuk melihat jam operasional";
    }

    if (distanceKm <= 5) {
      return "Jam pengiriman: 07:00 – 21:00";
    } else if (distanceKm <= 20) {
      return "Jam pengiriman: 08:00 – 18:00";
    } else {
      return "Jam pengiriman: 09:00 – 17:00";
    }
  }

  String _formatDate(DateTime date) {
    final List<String> days = [
      'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
    ];
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    String dayName = days[date.weekday % 7];
    String monthName = months[date.month - 1];

    return '$dayName, ${date.day} $monthName';
  }

  String _getDetailEstimasi() {
    if (distanceKm == 0) return "Belum ada estimasi";

    String hari = "";
    if (distanceKm <= 5) {
      hari = "1 hari kerja";
    } else if (distanceKm <= 15) {
      hari = "1-2 hari kerja";
    } else if (distanceKm <= 30) {
      hari = "2-3 hari kerja";
    } else {
      hari = "3-5 hari kerja";
    }

    return "$hari (${distanceKm.toStringAsFixed(1)} km)";
  }

  Color _getZonaBadgeColor() {
    if (distanceKm <= 5) {
      return Colors.green;
    } else if (distanceKm <= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getZonaBadgeText() {
    if (distanceKm <= 5) {
      return "DEKAT";
    } else if (distanceKm <= 20) {
      return "SEDANG";
    } else {
      return "JAUH";
    }
  }

  int get totalPoin {
    int poinPerItem = int.tryParse(widget.produk['poin']?.toString() ?? '0') ?? 0;
    return quantity * poinPerItem;
  }

  @override
  Widget build(BuildContext context) {
    _pageContext = context;
    pageContext = context;
    
    double totalHarga = _getTotalHarga();
    double voucherDiscount = _getVoucherDiscount();
    double finalShippingCost = _getFinalShippingCost();
    double effectivePrice = 0.0;
    int poinPerItem = int.tryParse(widget.produk['poin']?.toString() ?? '0') ?? 0;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0041c3),
        title: const Text(
          "Checkout dengan Poin",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Pengiriman ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$quantity Produk",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getEstimasiPengiriman(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedShipping ?? "Pilih ekspedisi terlebih dahulu",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),

                  // Location & Distance Info
                  if (customerLat != null && customerLng != null && distanceKm > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jarak: ${distanceKm.toStringAsFixed(2)} km dari toko',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getZonaDescription(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: Color(0xFF0041c3),
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getEstimasiSampai(),
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                _getJamOperasional(),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Produk ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: gambarUrl.isNotEmpty
                        ? Image.network(
                            gambarUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/image/produk.jpg',
                              width: 70,
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/image/produk.jpg',
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaProduk,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(deskripsi, style: const TextStyle(fontSize: 13)),
                        if (poinPerItem > 0)
                          Text(
                            'Poin per item: $poinPerItem',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              "${quantity}x   ",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(
                              Icons.monetization_on,
                              color: Color.fromARGB(255, 0, 193, 164),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$totalPoin",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 193, 164),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Ringkasan Pesanan ---
            Container(
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
                  _summaryRow(
                    "Total Poin ($quantity item)",
                    "$totalPoin Poin",
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryRow(
                        "Ongkos kirim",
                        finalShippingCost > 0
                            ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(finalShippingCost)
                            : "Belum dihitung",
                      ),
                      if (distanceKm > 0 && finalShippingCost > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Text(
                            '• ${_getDetailEstimasi()}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            if (finalShippingCost > 0)
                              Text(
                                "Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(finalShippingCost)}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0041c3),
                                ),
                              ),
                            if (finalShippingCost > 0)
                              const Text(
                                " + ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            Text(
                              "$totalPoin",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 193, 164),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              'assets/image/coin.png',
                              width: 18,
                              height: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Ekspedisi ---
            InkWell(
              onTap: () => _showShippingOptions(context),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pilih Ekspedisi",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "Pilih",
                          style: TextStyle(
                            color: Color(0xFF0041c3),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (selectedShipping != null) ...[
                      Row(
                        children: [
                          Icon(
                            _getShippingIcon(selectedShipping!),
                            color: const Color(0xFF0041c3),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      selectedShipping!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (distanceKm > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getZonaBadgeColor(),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getZonaBadgeText(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (shippingCost > 0)
                                  Text(
                                    "Ongkir: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(shippingCost)} • ${_getEstimasiPengiriman()}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  Text(
                                    _getEstimasiPengiriman(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueAccent,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          "Pilih ekspedisi pengiriman",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // --- Alamat ---
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailAlamatPage(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    selectedAddress = result;
                    if (result['latitude'] != null) {
                      customerLat = double.tryParse(result['latitude'].toString());
                    }
                    if (result['longitude'] != null) {
                      customerLng = double.tryParse(result['longitude'].toString());
                    }
                  });

                  if (selectedShipping == 'Ekspedisi Toko' && customerLat != null && customerLng != null) {
                    _calculateShippingCost();
                  }
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
                      children: [
                        const Text(
                          "Kirim ke Alamat",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          selectedAddress != null ? "Ubah Alamat" : "Tambahkan Alamat",
                          style: const TextStyle(
                            color: Color(0xFF0041c3),
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
                      child: selectedAddress != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${selectedAddress!['nama']} - ${selectedAddress!['hp']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Masukan detail alamat agar memudahkan pengiriman barang",
                                  style: TextStyle(
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
                                Row(
                                  children: [
                                    Icon(
                                      customerLat != null && customerLng != null
                                          ? Icons.location_on
                                          : Icons.location_off,
                                      size: 16,
                                      color: customerLat != null && customerLng != null
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        customerLat != null && customerLng != null
                                            ? "GPS aktif"
                                            : "GPS belum aktif. Aktifkan dulu supaya alamatmu terbaca dengan tepat.",
                                        style: TextStyle(
                                          color: customerLat != null && customerLng != null
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      // --- Tombol Pembayaran ---
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 193, 164),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => _handleTukarPoin(context),
          child: const Text(
            "Tukar Poin",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Extracted validation logic to separate method
  void _handleTukarPoin(BuildContext context) {
    // Validate expedition
    if (selectedShipping == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_shipping,
            color: Colors.red,
            size: 24,
          ),
        ),
        title: 'Ekspedisi Diperlukan',
        content: const Text('Mohon pilih ekspedisi pengiriman terlebih dahulu'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    // Validate address
    if (selectedAddress == null) {
      CustomDialog.show(
        context: context,
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_off,
            color: Colors.red,
            size: 24,
          ),
        ),
        title: 'Alamat Diperlukan',
        content: const Text('Mohon pilih alamat pengiriman terlebih dahulu'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    // Proceed with point exchange
    _showPointExchangeConfirmation(context);
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

  void _showShippingOptions(BuildContext context) {
    CustomModalBottomSheet.show(
      context: context,
      title: "Pilih Ekspedisi",
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_shipping,
          color: Colors.white,
          size: 28,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _shippingItem(Icons.store, "Ekspedisi Toko", enabled: true),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              "Segera Hadir",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            _shippingItem(Icons.local_shipping, "J&T", enabled: false),
            _shippingItem(Icons.delivery_dining, "SiCepat", enabled: false),
            _shippingItem(Icons.local_shipping_outlined, "JNE", enabled: false),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _shippingItem(IconData icon, String label, {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? Colors.blue.shade200 : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? Colors.white : Colors.grey.shade50,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: enabled ? const Color(0xFF0041c3) : Colors.grey,
          ),
          title: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: enabled ? Colors.black87 : Colors.grey,
                  decoration: enabled ? TextDecoration.none : TextDecoration.lineThrough,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Segera",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            enabled ? "Estimasi berdasarkan jarak" : "Belum tersedia",
            style: TextStyle(
              fontSize: 12,
              color: enabled ? Colors.black54 : Colors.grey,
            ),
          ),
          trailing: enabled
              ? const Icon(Icons.check_circle_outline, color: Color(0xFF0041c3))
              : const Icon(Icons.lock_outline, color: Colors.grey),
          enabled: enabled,
          onTap: enabled
              ? () async {
                  setState(() {
                    selectedShipping = label;
                  });
                  Navigator.pop(context);

                  if (customerLat != null && customerLng != null) {
                    await _calculateShippingCost();
                  } else {
                    if (mounted) {
                      CustomDialog.show(
                        context: context,
                        icon: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_off,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        title: 'Alamat Diperlukan',
                        content: const Text('Mohon pilih alamat terlebih dahulu untuk menghitung ongkir'),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }

  IconData _getShippingIcon(String shipping) {
    switch (shipping) {
      case "Ekspedisi Toko":
        return Icons.store;
      case "J&T":
        return Icons.local_shipping;
      case "SiCepat":
        return Icons.delivery_dining;
      case "JNE":
        return Icons.local_shipping_outlined;
      default:
        return Icons.local_shipping;
    }
  }

  void _onPaymentSuccess(BuildContext ctx, String orderCode) {
    debugPrint('Navigating to RiwayatPage from _onPaymentSuccess using global navigator');
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => const RiwayatPage(shouldRefresh: true),
      ),
    ).then((_) {
      debugPrint('Navigation to RiwayatPage from _onPaymentSuccess completed');
    }).catchError((e) {
      debugPrint('Navigation error from _onPaymentSuccess: $e');
    });
  }

  Future<void> _startMidtransPaymentForShipping(
    BuildContext ctx,
    String orderCode,
    int currentPoints,   // ✅ NEW: Current points before deduction
    String customerId,   // ✅ NEW: Customer ID
  ) async {
    debugPrint('════════════════════════════════════════════');
    debugPrint('🚀 STARTING MIDTRANS PAYMENT FOR SHIPPING');
    debugPrint('════════════════════════════════════════════');
    debugPrint('📦 Order Code: $orderCode');
    debugPrint('🚚 Shipping Cost: Rp ${shippingCost.toStringAsFixed(0)}');
    debugPrint('💰 Current Points: $currentPoints (NOT YET DEDUCTED)');
    debugPrint('════════════════════════════════════════════');

    try {
      int shippingAmount = shippingCost.toInt();
      if (shippingAmount <= 0) {
        debugPrint('✅ Shipping is free');
        // Potong poin karena gratis ongkir
        await _deductPointsAndShowSuccess(ctx, orderCode, currentPoints, customerId);
        return;
      }

      final deliveryAddr = selectedAddress?['detailAlamat']?.toString() ??
                           selectedAddress?['alamat']?.toString() ??
                           'Alamat tidak tersedia';

      debugPrint('💳 Initiating Midtrans for shipping: Rp $shippingAmount');

      await PaymentService.startShippingPayment(
        context: ctx,
        orderCode: orderCode,
        customerId: customerId,
        shippingCost: shippingCost,
        customerName: selectedAddress?['nama']?.toString() ?? 'Customer',
        customerPhone: selectedAddress?['hp']?.toString() ?? '08123456789',
        pointsUsed: totalPoin,
        deliveryAddress: deliveryAddr,
        customerLat: customerLat,
        customerLng: customerLng,
        onTransactionFinished: (result) async {
          debugPrint('════════════════════════════════════════════');
          debugPrint('💳 MIDTRANS CALLBACK RECEIVED');
          debugPrint('💳 Result: $result');
          debugPrint('════════════════════════════════════════════');

          // ✅ Handle result - POTONG POIN HANYA JIKA SUCCESS!
          if (PaymentService.isTransactionSuccess(result)) {
            debugPrint('✅ Payment SUCCESS! Now deducting points...');

            // ✅ POTONG POIN DI SINI (setelah payment success)
            await _deductPointsAndShowSuccess(ctx, orderCode, currentPoints, customerId);

          } else if (result == 'pending') {
            debugPrint('⏳ Payment PENDING - Points NOT deducted yet');

            // ✅ Poin TIDAK dipotong untuk pending
            // Akan dipotong oleh webhook saat status jadi settlement
            if (mounted) {
              _showPaymentPendingDialog(ctx, orderCode);
            }
          } else {
            debugPrint('❌ Payment FAILED/CANCELLED - Points NOT deducted');

            // ✅ Poin TIDAK dipotong
            // Tanya user mau cancel order atau bayar lagi
            if (mounted) {
              _showPaymentCancelledDialog(ctx, result, orderCode);
            }
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting Midtrans: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      if (mounted) {
        // ✅ Poin TIDAK dipotong jika error
        _showPaymentErrorDialog(ctx, orderCode, e.toString());
      }
    }
  }

  // ✅ FIXED: Complete rewrite of _showPointExchangeConfirmation with correct bracket structure
  void _showPointExchangeConfirmation(BuildContext context) {
    CustomDialog.show(
      context: context,
      icon: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 193, 164).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.monetization_on,
          color: Color.fromARGB(255, 0, 193, 164),
          size: 50,
        ),
      ),
      title: "Apakah ingin menukar poin?",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_getFinalShippingCost() > 0) ...[
            const SizedBox(height: 10),
            const Text(
              "Anda akan melanjutkan pembayaran ongkir",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Batal",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => _processPointExchange(context),
          child: const Text('Ya'),
        ),
      ],
    );
  }

  // ✅ FIXED: Updated payload to match backend requirements
  Future<void> _processPointExchange(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop(); // Close confirmation dialog

    if (!mounted) return;

    final currentContext = context;

    // Show loading dialog
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (loadingContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color.fromARGB(255, 0, 193, 164),
              ),
              const SizedBox(height: 20),
              Text(
                'Sedang memproses...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get user session
      final session = await SessionManager.getUserSession();
      final customerId = session['id']?.toString();

      if (customerId == null || customerId.isEmpty) {
        throw Exception('User tidak ditemukan. Silakan login ulang.');
      }

      debugPrint('📱 Customer ID: $customerId');

      // Get current user points
      final userDataResponse = await ApiService.getCostomerById(customerId);
      final currentPoints = int.tryParse(userDataResponse['cos_poin']?.toString() ?? '0') ?? 0;

      debugPrint('💰 Current Points: $currentPoints, Required: $totalPoin');

      // Check if user has enough points
      if (currentPoints < totalPoin) {
        throw Exception(
          'Poin tidak mencukupi.\n'
          'Dibutuhkan: $totalPoin poin\n'
          'Anda memiliki: $currentPoints poin'
        );
      }

      // Prepare items
      final items = [
        {
          'kode_barang': widget.produk['kode_barang']?.toString() ?? '',
          'nama_produk': widget.produk['nama_produk']?.toString() ?? 'Produk',
          'price': 0,
          'quantity': quantity,
        }
      ];

      final shippingCostToPay = _getFinalShippingCost();
      final deliveryAddr = selectedAddress!['detailAlamat']?.toString() ?? '';

      debugPrint('📦 Order Items: $items');
      debugPrint('🎯 Points Used: $totalPoin');
      debugPrint('🚚 Shipping Cost: $shippingCostToPay');

      // ✅ Step 1: Create order (TANPA potong poin dulu!)
      final orderResponse = await ApiService.createCheckoutOrderWithPoints(
        customerId: customerId,
        items: items,
        deliveryAddress: deliveryAddr,
        customerLat: customerLat ?? 0.0,
        customerLng: customerLng ?? 0.0,
        pointsUsed: totalPoin,  // Dicatat di database, tapi poin belum dipotong
        shippingCost: shippingCostToPay,
      );

      debugPrint('📋 Order Response: $orderResponse');

      if (orderResponse == null || orderResponse['success'] != true) {
        String errorMessage = _extractErrorMessage(orderResponse ?? {});
        throw Exception(errorMessage);
      }

      final orderCode = orderResponse['data']?['order_code']?.toString() ?? '';

      if (orderCode.isEmpty) {
        throw Exception('Order code tidak ditemukan dalam response');
      }

      debugPrint('✅ Order created successfully: $orderCode');

      // ⚠️ POIN BELUM DIPOTONG DI SINI!
      // Poin akan dipotong SETELAH pembayaran berhasil

      // Close loading dialog
      if (mounted && Navigator.canPop(currentContext)) {
        Navigator.of(currentContext).pop();
      }

      // ✅ Step 2: Handle payment
      if (shippingCostToPay > 0) {
        debugPrint('🚚 Opening Midtrans for shipping payment...');

        if (mounted) {
          await _startMidtransPaymentForShipping(
            currentContext,
            orderCode,
            currentPoints,  // ✅ Pass current points untuk dipotong nanti
            customerId,     // ✅ Pass customer ID
          );
        }
      } else {
        // ✅ No shipping cost = gratis ongkir
        // Langsung potong poin karena tidak perlu bayar apapun
        debugPrint('✅ No shipping cost, deducting points now...');

        final newPoints = currentPoints - totalPoin;
        await ApiService.updateCostomer(customerId, {'cos_poin': newPoints.toString()});
        UserPointData.setPoints(newPoints);

        debugPrint('💰 Points deducted. New balance: $newPoints');

        // Update order status to paid (karena tidak ada yang perlu dibayar)
        await _updatePaymentStatusAfterSuccess(orderCode);

        if (mounted) {
          _showPaymentSuccessDialog(currentContext, orderCode);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error during point exchange: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Close loading dialog if still open
      if (mounted && Navigator.canPop(currentContext)) {
        Navigator.of(currentContext).pop();
      }

      if (mounted) {
        _showErrorDialog(currentContext, e.toString());
      }
    }
  }

  // ✅ NEW: Helper to extract error message from response
  String _extractErrorMessage(Map<String, dynamic> response) {
    String errorMessage = response['message']?.toString() ?? 'Gagal membuat pesanan';

    if (response['errors'] != null) {
      final errors = response['errors'];
      if (errors is Map) {
        List<String> errorList = [];
        errors.forEach((key, value) {
          if (value is List) {
            errorList.addAll(value.map((e) => '• $e'));
          } else {
            errorList.add('• $value');
          }
        });
        if (errorList.isNotEmpty) {
          errorMessage = errorList.join('\n');
        }
      }
    }

    return errorMessage;
  }

  void _showSuccessDialog(BuildContext ctx, String orderCode) {
    final shippingCostToPay = _getFinalShippingCost();

    CustomDialog.show(
      context: ctx,
      icon: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 50,
        ),
      ),
      title: 'Penukaran Berhasil!',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Points used info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 193, 164).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color.fromARGB(255, 0, 193, 164),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalPoin Poin',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 193, 164),
                      ),
                    ),
                    Text(
                      'telah ditukarkan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Product info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: gambarUrl.isNotEmpty
                      ? Image.network(
                          gambarUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaProduk,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${quantity}x',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Shipping info
          if (shippingCostToPay > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ongkir ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(shippingCostToPay)} sudah dibayar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.green[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gratis ongkir!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          Text(
            'Kode Pesanan: $orderCode',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const RiwayatPage(shouldRefresh: true),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 193, 164),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: Text(
            'Lihat Riwayat Pesanan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Show success dialog after payment is complete
  void _showPaymentSuccessDialog(BuildContext ctx, String orderCode) {
    final shippingCostPaid = _getFinalShippingCost();

    showDialog(
      context: ctx,
      barrierDismissible: false,  // User harus klik OK
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with Animation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              'Transaksi Berhasil!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Points exchanged info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 193, 164).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 193, 164).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color.fromARGB(255, 0, 193, 164),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalPoin Poin',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 193, 164),
                        ),
                      ),
                      Text(
                        'Berhasil ditukarkan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Product info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: gambarUrl.isNotEmpty
                        ? Image.network(
                            gambarUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaProduk,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${quantity}x',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Shipping paid info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.green[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ongkir Sudah Dibayar',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(shippingCostPaid),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Order code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Kode: $orderCode',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // ✅ Close dialog first
                Navigator.of(dialogContext).pop();

                // ✅ Then navigate to Riwayat
                Navigator.of(ctx).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const RiwayatPage(shouldRefresh: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 193, 164),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  /// ✅ NEW: Show pending dialog (e.g., for bank transfer)
  void _showPaymentPendingDialog(BuildContext ctx, String orderCode) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty,
                color: Colors.orange,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Menunggu Pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Penukaran poin Anda sudah berhasil!\n\nSilakan selesaikan pembayaran ongkir untuk melanjutkan proses pengiriman.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anda dapat melakukan pembayaran melalui halaman Riwayat Pesanan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Kode: $orderCode',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(ctx).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const RiwayatPage(shouldRefresh: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Lihat Riwayat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  void _showPaymentFailedDialog(BuildContext ctx, dynamic result, String orderCode) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel,
                color: Colors.red,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Pembayaran Dibatalkan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Penukaran $totalPoin poin sudah berhasil disimpan!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Anda dapat membayar ongkir nanti melalui halaman Riwayat Pesanan.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Kode: $orderCode',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(ctx).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const RiwayatPage(shouldRefresh: true),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Nanti',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    // Get fresh data and retry
                    final session = await SessionManager.getUserSession();
                    final customerId = session['id']?.toString() ?? '';
                    final userData = await ApiService.getCostomerById(customerId);
                    final currentPoints = int.tryParse(userData['cos_poin']?.toString() ?? '0') ?? 0;
                    _startMidtransPaymentForShipping(ctx, orderCode, currentPoints, customerId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0041c3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Bayar Lagi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  // ✅ Helper: Check if Midtrans result is SUCCESS
  bool _isMidtransSuccess(dynamic result) {
    if (result == null) return false;

    if (result is String) {
      final status = result.toLowerCase();
      return status == 'success' ||
             status == 'settlement' ||
             status == 'capture' ||
             status == 'completed';
    }

    if (result is Map) {
      final status = result['status']?.toString().toLowerCase() ??
                     result['transaction_status']?.toString().toLowerCase() ?? '';
      return status == 'success' ||
             status == 'settlement' ||
             status == 'capture' ||
             status == 'completed';
    }

    // Check PaymentService helper if available
    try {
      return PaymentService.isTransactionSuccess(result);
    } catch (e) {
      return false;
    }
  }

  // ✅ Helper: Check if Midtrans result is PENDING
  bool _isMidtransPending(dynamic result) {
    if (result == null) return false;

    if (result is String) {
      final status = result.toLowerCase();
      return status == 'pending';
    }

    if (result is Map) {
      final status = result['status']?.toString().toLowerCase() ??
                     result['transaction_status']?.toString().toLowerCase() ?? '';
      return status == 'pending';
    }

    return false;
  }

  // ✅ NEW: Update payment status after successful payment
  Future<void> _updatePaymentStatusAfterSuccess(String orderCode) async {
    debugPrint('📤 Updating payment status for order: $orderCode');

    try {
      // ✅ Use the correct endpoint: PUT /api/checkout/update-payment-status/{orderCode}
      final response = await ApiService.updateOrderPaymentStatus(
        orderCode: orderCode,
        status: 'paid',
      );

      if (response['success'] == true) {
        debugPrint('✅ Payment status updated successfully');
      } else {
        debugPrint('⚠️ Failed to update payment status: ${response['message']}');
        // Don't throw - webhook will handle it
      }
    } catch (e) {
      debugPrint('⚠️ Error updating payment status: $e');
      // Don't throw - Midtrans webhook will handle the update
      // The payment is still successful from user perspective
    }
  }

  // ✅ NEW: Separate method for error dialog
  void _showErrorDialog(BuildContext ctx, String errorMessage) {
    CustomDialog.show(
      context: ctx,
      icon: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 50,
        ),
      ),
      title: 'Gagal',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            errorMessage.replaceAll('Exception: ', ''),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'OK',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Deduct points and show success
  Future<void> _deductPointsAndShowSuccess(
    BuildContext ctx,
    String orderCode,
    int currentPoints,
    String customerId,
  ) async {
    try {
      // Potong poin
      final newPoints = currentPoints - totalPoin;
      await ApiService.updateCostomer(customerId, {'cos_poin': newPoints.toString()});
      UserPointData.setPoints(newPoints);

      debugPrint('💰 Points deducted: $totalPoin');
      debugPrint('💰 New balance: $newPoints');

      // Update payment status
      await _updatePaymentStatusAfterSuccess(orderCode);

      // Show success dialog
      if (mounted) {
        _showPaymentSuccessDialog(ctx, orderCode);
      }
    } catch (e) {
      debugPrint('❌ Error deducting points: $e');
      // Tetap show success untuk payment, tapi log error
      if (mounted) {
        _showPaymentSuccessDialog(ctx, orderCode);
      }
    }
  }

  // ✅ NEW: Dialog when user cancels payment
  void _showPaymentCancelledDialog(BuildContext ctx, dynamic result, String orderCode) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 60,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Pembayaran Dibatalkan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // ✅ Info: Poin TIDAK dipotong
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Poin Anda tidak terpotong',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Pesanan Anda masih tersimpan. Anda dapat melanjutkan pembayaran nanti dari halaman Riwayat.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Kode: $orderCode',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
          actions: [
            Column(
              children: [
                // Bayar Sekarang
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();

                      // Get fresh data and retry
                      final session = await SessionManager.getUserSession();
                      final customerId = session['id']?.toString() ?? '';
                      final userData = await ApiService.getCostomerById(customerId);
                      final currentPoints = int.tryParse(userData['cos_poin']?.toString() ?? '0') ?? 0;

                      _startMidtransPaymentForShipping(ctx, orderCode, currentPoints, customerId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0041c3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Bayar Sekarang',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Bayar Nanti
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(ctx).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const RiwayatPage(shouldRefresh: true),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Bayar Nanti',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Batalkan Pesanan
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _cancelOrder(ctx, orderCode);
                  },
                  child: Text(
                    'Batalkan Pesanan',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        ),
      ),
    );
  }

  // ✅ NEW: Cancel order function
  Future<void> _cancelOrder(BuildContext ctx, String orderCode) async {
    try {
      // Show loading
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (c) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Membatalkan pesanan...'),
            ],
          ),
        ),
      );

      // Cancel order via API
      await ApiService.updateOrderPaymentStatus(
        orderCode: orderCode,
        status: 'cancelled',
      );

      Navigator.of(ctx).pop(); // Close loading

      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RiwayatPage(shouldRefresh: true),
        ),
      );
    } catch (e) {
      Navigator.of(ctx).pop(); // Close loading
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan pesanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ NEW: Error dialog
  void _showPaymentErrorDialog(BuildContext ctx, String orderCode, String error) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Terjadi Kesalahan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Poin Anda tidak terpotong',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal membuka pembayaran. Silakan coba lagi dari halaman Riwayat.',
              style: GoogleFonts.poppins(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const RiwayatPage(shouldRefresh: true),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
