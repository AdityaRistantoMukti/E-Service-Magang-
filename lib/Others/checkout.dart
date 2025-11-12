import 'dart:convert';
import 'package:e_service/Service/detail_alamat.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'struck_pesanan.dart';
import '../api_services/payment_service.dart';
import '../api_services/api_service.dart';
import '../Others/session_manager.dart';
import '../Others/user_point_data.dart';
import '../models/promo_model.dart';
import '../config/api_config.dart';

class CheckoutPage extends StatefulWidget {
  final bool? usePointsFromPromo;
  final Map<String, dynamic> produk;
  const CheckoutPage({
    super.key,
    this.usePointsFromPromo,
    required this.produk,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedPaymentMethod;
  String? selectedShipping;
  Map<String, dynamic>? selectedAddress;
  bool usePoints = false;
  bool useVoucher = false;
  String? selectedVoucher;
  late String namaProduk;
  late String deskripsi;
  String gambarUrl = '';
  List<Promo> promoList = [];
  bool isPromoLoaded = false;
  double? hargaAsli;
  
  // Inisialisasi quantity dan totalPoin
  late int quantity;
  late int totalPoin;

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
    if (widget.usePointsFromPromo != null) {
      usePoints = widget.usePointsFromPromo!;
    }
    namaProduk = widget.produk['nama_produk']?.toString() ?? 'Produk Tidak Dikenal';
    deskripsi = widget.produk['deskripsi']?.toString() ?? 'Deskripsi tidak tersedia';
    gambarUrl = getFirstImageUrl(widget.produk['gambar']);

    // Initialize quantity dari produk, default 1 jika tidak ada
    quantity = widget.produk['quantity'] ?? 1;

    // Calculate total poin
    int poinPerItem = int.tryParse(widget.produk['poin']?.toString() ?? '0') ?? 0;
    totalPoin = poinPerItem * quantity;

    _fetchPromo();
    _fetchHargaAsli();
    _getCurrentLocation();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        customerLat = position.latitude;
        customerLng = position.longitude;
      });

      debugPrint('📍 Current Location: $customerLat, $customerLng');
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Calculate shipping cost
  Future<void> _calculateShippingCost() async {
    if (customerLat == null || customerLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi belum terdeteksi. Mohon aktifkan GPS.'),
          backgroundColor: Colors.orange,
        ),
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
        setState(() {
          shippingCost = double.tryParse(data['shipping_cost']?.toString() ?? '0') ?? 0.0;
          distanceKm = double.tryParse(data['distance_km']?.toString() ?? '0') ?? 0.0;
          isCalculatingShipping = false;
        });

        debugPrint('✅ Shipping calculated: Rp $shippingCost (${distanceKm}km)');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ongkir berhasil dihitung: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(shippingCost)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Gagal menghitung ongkir');
      }
    } catch (e) {
      setState(() {
        isCalculatingShipping = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghitung ongkir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchHargaAsli() async {
    String kodeBarang = widget.produk['kode_barang']?.toString() ?? '';
    if (kodeBarang.isNotEmpty) {
      try {
        final produkList = await ApiService.getProduk();
        final produk = produkList.firstWhere(
          (p) => p['kode_barang']?.toString() == kodeBarang,
          orElse: () => null,
        );
        if (produk != null) {
          setState(() {
            hargaAsli = (double.tryParse(produk['harga']?.toString() ?? '0') ?? 0.0) * 10;
          });
        }
      } catch (e) {
        debugPrint("Error fetching harga asli: $e");
      }
    }
  }

  Future<void> _fetchPromo() async {
    try {
      final response = await ApiService.getPromo();
      setState(() {
        promoList = response.map<Promo>((json) => Promo.fromJson(json)).toList();
        isPromoLoaded = true;
      });
    } catch (e) {
      setState(() {
        isPromoLoaded = true;
      });
      debugPrint("Error loading promo: $e");
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

    // If it's already a full URL, return as is
    if (gambarString.startsWith('http')) {
      return gambarString;
    }

    // Check if string contains multiple URLs separated by commas
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

    // Add assets/image/ path if not already a full URL
    if (!cleanPath.startsWith('http')) {
      cleanPath = 'assets/image/' + cleanPath;
    }

    String imageUrl = cleanPath.startsWith('http') ? cleanPath : '$baseUrl$cleanPath';

    return imageUrl;
  }

  // Helper function to clean image path for getFirstImageUrl
  String _cleanImagePath(String path) {
    path = path.trim();

    // Remove any leading slash
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Remove base URL if present
    path = path.replaceAll(ApiConfig.storageBaseUrl, '');

    return path;
  }

  // Helper untuk mendapatkan total harga
  double _getTotalHarga() {
    double hargaPerItem = (double.tryParse(widget.produk['harga']?.toString() ?? '0') ?? 0.0) * 10;
    return hargaPerItem * quantity;
  }

  // Helper untuk mendapatkan diskon voucher
  double _getVoucherDiscount() {
    if (!useVoucher || selectedVoucher == null) return 0.0;
    
    final voucher = availableVouchers.firstWhere(
      (v) => v['code'] == selectedVoucher,
      orElse: () => {},
    );
    
    if (voucher.isEmpty) return 0.0;
    
    double totalHarga = _getTotalHarga();
    
    // Check minimum purchase
    if (totalHarga < voucher['minPurchase']) return 0.0;
    
    return totalHarga * voucher['discount'];
  }

  // Helper untuk check gratis ongkir dari voucher
  bool _hasVoucherFreeShipping() {
    if (!useVoucher || selectedVoucher == null) return false;
    
    final voucher = availableVouchers.firstWhere(
      (v) => v['code'] == selectedVoucher,
      orElse: () => {},
    );
    
    return voucher['freeShipping'] ?? false;
  }

  // Get final shipping cost (consider voucher)
  double _getFinalShippingCost() {
    if (_hasVoucherFreeShipping()) {
      return 0.0;
    }
    return shippingCost;
  }

  // Helper untuk mendapatkan estimasi pengiriman berdasarkan jarak
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

  // Helper untuk mendapatkan deskripsi zona
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

  // Helper untuk mendapatkan estimasi sampai yang lebih detail
  String _getEstimasiSampai() {
    if (distanceKm == 0 || selectedShipping == null) {
      return "Estimasi akan muncul setelah memilih lokasi";
    }
    
    DateTime now = DateTime.now();
    DateTime estimatedDate;
    
    if (distanceKm <= 5) {
      // Zona dekat: 1 hari
      estimatedDate = now.add(const Duration(days: 1));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Besok)";
    } else if (distanceKm <= 15) {
      // Zona menengah dekat: 1-2 hari
      estimatedDate = now.add(const Duration(days: 2));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 2 hari)";
    } else if (distanceKm <= 30) {
      // Zona menengah jauh: 2-3 hari
      estimatedDate = now.add(const Duration(days: 3));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 3 hari)";
    } else {
      // Zona jauh: 3-5 hari
      estimatedDate = now.add(const Duration(days: 5));
      return "Estimasi sampai: ${_formatDate(estimatedDate)} (Maks. 5 hari)";
    }
  }

  // Helper untuk mendapatkan jam operasional berdasarkan zona
  String _getJamOperasional() {
    if (distanceKm == 0) {
      return "Pilih lokasi untuk melihat jam operasional";
    }
    
    if (distanceKm <= 5) {
      // Zona dekat: pengiriman bisa sore/malam
      return "Jam pengiriman: 07:00 – 21:00";
    } else if (distanceKm <= 20) {
      // Zona menengah: pengiriman jam kerja saja
      return "Jam pengiriman: 08:00 – 18:00";
    } else {
      // Zona jauh: pengiriman terbatas
      return "Jam pengiriman: 09:00 – 17:00";
    }
  }

  // Helper untuk format tanggal Indonesia
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

  // Helper untuk mendapatkan detail estimasi untuk summary
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

  // Helper untuk warna badge zona
  Color _getZonaBadgeColor() {
    if (distanceKm <= 5) {
      return Colors.green;
    } else if (distanceKm <= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Helper untuk text badge zona
  String _getZonaBadgeText() {
    if (distanceKm <= 5) {
      return "DEKAT";
    } else if (distanceKm <= 20) {
      return "SEDANG";
    } else {
      return "JAUH";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan total harga berdasarkan quantity
    double totalHarga = _getTotalHarga();
    double voucherDiscount = _getVoucherDiscount();
    double finalShippingCost = _getFinalShippingCost();
    double effectivePrice = usePoints 
        ? 0.0 
        : (hargaAsli != null 
            ? (hargaAsli! * quantity) - voucherDiscount + finalShippingCost
            : totalHarga - voucherDiscount + finalShippingCost);
    int poinPerItem = int.tryParse(widget.produk['poin']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Ringkasan Pesanan",
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
                          color: Colors.blue,
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
                        if (poinPerItem > 0 && usePoints)
                          Text(
                            'Poin per item: $poinPerItem',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 6),
                        usePoints
                            ? Row(
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
                              )
                            : Text(
                                "${quantity}x   ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format((totalHarga + voucherDiscount) / quantity)}",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
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
                  usePoints
                      ? _summaryRow(
                          "Total Poin ($quantity item)",
                          "$totalPoin Poin",
                        )
                      : _summaryRow(
                          "Subtotal ($quantity item)",
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(hargaAsli != null ? (hargaAsli! * quantity) : totalHarga),
                        ),

                  if (!usePoints) ...[
                    _summaryRow("Diskon", "Rp 0"),
                    if (useVoucher && voucherDiscount > 0)
                      _summaryRow(
                        "Voucher",
                        "- ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(voucherDiscount)}",
                        color: Colors.green,
                      )
                    else
                      _summaryRow("Voucher", "Rp 0"),
                  ],

                  // Ongkos kirim selalu ditampilkan untuk promo products
                  if (usePoints) ...[
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
                  ] else ...[
                    // Update bagian ongkir dengan detail untuk non-promo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryRow(
                          "Ongkos kirim",
                          _hasVoucherFreeShipping()
                              ? "Gratis"
                              : (finalShippingCost > 0
                                  ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(finalShippingCost)
                                  : "Belum dihitung"),
                          color: _hasVoucherFreeShipping() ? Colors.green : null,
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
                  ],

                  const Divider(),
                  usePoints
                      ? Padding(
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
                                        color: Colors.blue,
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
                        )
                      : _summaryRow(
                          "Total Belanja",
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(effectivePrice),
                          isTotal: true,
                          color: Colors.blue,
                        ),
                ],
              ),
            ),

            const SizedBox(height: 8),



            const SizedBox(height: 8),

            // --- Toggle Gunakan Voucher ---
            if (!usePoints) ...[
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Gunakan Voucher",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (useVoucher && selectedVoucher != null)
                              Text(
                                selectedVoucher!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (useVoucher)
                              TextButton(
                                onPressed: () => _showVoucherOptions(context),
                                child: const Text(
                                  "Pilih",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            Switch(
                              value: useVoucher,
                              activeThumbColor: Colors.blue,
                              onChanged: (value) {
                                setState(() {
                                  useVoucher = value;
                                  if (useVoucher) {
                                    _showVoucherOptions(context);
                                  } else {
                                    selectedVoucher = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
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
                            color: Colors.blue,
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
                            color: Colors.blue,
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
                                if (shippingCost > 0 && !_hasVoucherFreeShipping())
                                  Text(
                                    "Ongkir: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(shippingCost)} • ${_getEstimasiPengiriman()}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  )
                                else if (_hasVoucherFreeShipping())
                                  Text(
                                    "Gratis Ongkir (Voucher) • ${_getEstimasiPengiriman()}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                    // Update koordinat jika ada di result
                    if (result['latitude'] != null) {
                      customerLat = double.tryParse(result['latitude'].toString());
                    }
                    if (result['longitude'] != null) {
                      customerLng = double.tryParse(result['longitude'].toString());
                    }
                  });
                  
                  // Auto calculate shipping jika ada ekspedisi dan koordinat
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
                      children: const [
                        Text(
                          "Kirim ke Alamat",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "Tambahkan Alamat",
                          style: TextStyle(
                            color: Colors.blue,
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
            backgroundColor: usePoints
                ? const Color.fromARGB(255, 0, 193, 164)
                : Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: usePoints
              ? () => _showPointExchangeConfirmation(context)
              : () => _processCheckout(context),
          child: Text(
            usePoints ? "Tukar Poin" : "Lakukan Pembayaran",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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

  void _showVoucherOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Voucher",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ...availableVouchers.map((voucher) {
                double totalHarga = _getTotalHarga();
                bool canUse = totalHarga >= voucher['minPurchase'];
                
                return _voucherItem(
                  voucher['code'],
                  voucher['name'],
                  voucher['description'],
                  canUse,
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _voucherItem(String code, String name, String description, bool canUse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: canUse ? Colors.blue : Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: canUse ? Colors.blue.shade50 : Colors.grey.shade100,
      ),
      child: ListTile(
        leading: Icon(
          Icons.local_offer,
          color: canUse ? Colors.blue : Colors.grey,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: canUse ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: canUse ? Colors.black54 : Colors.grey,
          ),
        ),
        trailing: canUse
            ? const Icon(Icons.check_circle_outline, color: Colors.blue)
            : const Icon(Icons.lock_outline, color: Colors.grey),
        enabled: canUse,
        onTap: canUse
            ? () {
                setState(() {
                  selectedVoucher = code;
                  useVoucher = true;
                });
                Navigator.pop(context);
              }
            : null,
      ),
    );
  }

  void _showShippingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Pilih Ekspedisi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),

                // Ekspedisi aktif (hanya Ekspedisi Toko)
                _shippingItem(Icons.store, "Ekspedisi Toko", enabled: true),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Label untuk ekspedisi yang tidak tersedia
                const Text(
                  "Segera Hadir",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Ekspedisi disabled - make this scrollable if needed
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _shippingItem(Icons.local_shipping, "J&T", enabled: false),
                        _shippingItem(Icons.delivery_dining, "SiCepat", enabled: false),
                        _shippingItem(Icons.local_shipping_outlined, "JNE", enabled: false),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
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
            color: enabled ? Colors.blue : Colors.grey,
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
              ? const Icon(Icons.check_circle_outline, color: Colors.blue)
              : const Icon(Icons.lock_outline, color: Colors.grey),
          enabled: enabled,
          onTap: enabled
              ? () async {
                  setState(() {
                    selectedShipping = label;
                  });
                  Navigator.pop(context);
                  
                  // Auto calculate shipping jika sudah ada alamat
                  if (customerLat != null && customerLng != null) {
                    await _calculateShippingCost();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mohon pilih alamat terlebih dahulu untuk menghitung ongkir'),
                        backgroundColor: Colors.orange,
                      ),
                    );
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

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case "Transfer Bank BCA":
        return Icons.account_balance;
      case "Transfer Bank BRI":
        return Icons.account_balance_wallet;
      case "Transfer Bank Mandiri":
        return Icons.account_balance_rounded;
      default:
        return Icons.account_balance;
    }
  }

  // Process checkout and create order
  Future<void> _processCheckout(BuildContext context) async {
    // Validasi
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih alamat pengiriman'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedShipping == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih ekspedisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (customerLat == null || customerLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi belum terdeteksi. Mohon aktifkan GPS.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (shippingCost == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ongkir belum dihitung. Mohon tunggu sebentar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String? customerId = await SessionManager.getCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID tidak ditemukan');
      }

      // Calculate prices
      double totalHarga = _getTotalHarga();
      double voucherDiscount = _getVoucherDiscount();
      double finalShippingCost = _getFinalShippingCost();

      // For promo products, only charge shipping cost
      double finalPrice = usePoints ? finalShippingCost : (totalHarga - voucherDiscount + finalShippingCost);

      // Prepare items untuk API
      List<Map<String, dynamic>> items = [
        {
          'kode_barang': widget.produk['kode_barang'] ?? widget.produk['id_produk'] ?? 'PROD001',
          'nama_produk': namaProduk,
          'quantity': quantity,
          'price': usePoints ? 0 : (totalHarga / quantity).toInt(), // No product cost for promo
        }
      ];

      // Calculate voucher discount percent
      double voucherDiscountPercent = 0.0;
      if (selectedVoucher != null && voucherDiscount > 0) {
        voucherDiscountPercent = voucherDiscount / totalHarga;
      }

      // Create order via API
      final orderResponse = await ApiService.createCheckoutOrder(
        customerId: customerId,
        items: items,
        totalPrice: finalPrice, // Use final price (shipping only for promo)
        paymentMethod: 'midtrans',
        deliveryAddress: selectedAddress!['detailAlamat'],
        customerLat: customerLat!,
        customerLng: customerLng!,
        voucherCode: selectedVoucher,
        voucherDiscount: voucherDiscountPercent,
      );

      if (orderResponse['success'] == true) {
        final orderData = orderResponse['data'];
        final orderCode = orderData['order_code'];

        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // Start Midtrans payment
        await _startMidtransPayment(context, orderCode);
      } else {
        throw Exception(orderResponse['message'] ?? 'Gagal membuat order');
      }
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startMidtransPayment(BuildContext context, String orderCode) async {
    try {
      String? customerId = await SessionManager.getCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID tidak ditemukan');
      }

      double totalHarga = _getTotalHarga();
      double voucherDiscount = _getVoucherDiscount();
      double finalShippingCost = _getFinalShippingCost();
      double finalPrice = usePoints ? finalShippingCost : (totalHarga - voucherDiscount + finalShippingCost);

      await PaymentService.startMidtransPayment(
        context: context,
        orderId: orderCode,
        amount: finalPrice.toInt() > 0 ? finalPrice.toInt() : 1000,
        customerId: customerId,
        customerName: selectedAddress?['nama'] ?? 'Customer',
        customerEmail: 'customer@example.com',
        customerPhone: selectedAddress?['hp'] ?? '08123456789',
        itemDetails: [
          if (!usePoints) // Only include product if not using points
            {
              'id': widget.produk['kode_barang']?.toString() ??
                  widget.produk['id_produk']?.toString() ??
                  'PROD001',
              'price': ((totalHarga - voucherDiscount) / quantity).toInt(),
              'quantity': quantity,
              'name': namaProduk,
            },
          if (finalShippingCost > 0)
            {
              'id': 'SHIPPING',
              'price': finalShippingCost.toInt(),
              'quantity': 1,
              'name': 'Ongkos Kirim',
            }
        ],
        onTransactionFinished: (result) async {
          print('Payment Result - Status: $result');

          if (PaymentService.isTransactionSuccess(result)) {
            // Update payment status
            await ApiService.updatePaymentStatus(
              orderCode: orderCode,
              paymentStatus: 'paid',
            );

            // Deduct points for promo products
            if (usePoints) {
              final session = await SessionManager.getUserSession();
              final userId = session['id'];
              if (userId != null) {
                int userPoints = UserPointData.userPoints.value;
                final newPoints = userPoints - totalPoin;
                await ApiService.updateCostomer(userId, {'cos_poin': newPoints.toString()});
                UserPointData.setPoints(newPoints);
              }
            }

            _onPaymentSuccess(orderCode);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(PaymentService.getStatusMessage(result)),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPaymentSuccess(String orderCode) {
    double totalHarga = _getTotalHarga();
    double voucherDiscount = _getVoucherDiscount();
    double finalShippingCost = _getFinalShippingCost();
    double finalPrice = totalHarga - voucherDiscount + finalShippingCost;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StruckPesananPage(
          serviceType: 'shop',
          nama: selectedAddress?['nama'] ?? 'User',
          jumlahBarang: quantity,
          items: [
            {
              'merek': namaProduk,
              'device': deskripsi,
              'seri': 'Order: $orderCode',
            },
          ],
          alamat: selectedAddress?['detailAlamat'] ?? 'Atur alamat anda di sini',
          totalHarga: NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(finalPrice),
        ),
      ),
    );
  }

  void _showPointExchangeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
              const SizedBox(height: 20),
              const Text(
                "Apakah ingin menukar poin?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if (_getFinalShippingCost() > 0) ...[
                const SizedBox(height: 10),
                Text(
                  "Anda akan melanjutkan pembayaran ongkir",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      _validatePointsAndProceed(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 193, 164),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Ya, Tukar",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _validatePointsAndProceed(BuildContext context) {
    // Check if user has enough points
    final userPoints = UserPointData.userPoints.value;
    final requiredPoints = totalPoin;

    if (userPoints < requiredPoints) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
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
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Poin Tidak Cukup",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Anda membutuhkan $requiredPoints poin, tetapi hanya memiliki $userPoints poin.",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // If points are sufficient, proceed to Midtrans payment
    _processPointExchangeWithMidtrans(context);
  }

  void _processPointExchangeWithMidtrans(BuildContext context) async {
    // Validasi
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih alamat pengiriman'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedShipping == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih ekspedisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Create order data for point exchange
      final orderData = {
        'produk': widget.produk,
        'alamat': selectedAddress,
        'ekspedisi': selectedShipping,
        'total_harga': _getFinalShippingCost(),
        'poin_digunakan': totalPoin,
        'use_points': true,
      };

      // Process payment with Midtrans
      final paymentResult = await PaymentService.startMidtransPayment(
        context: context,
        orderId: 'promo_${DateTime.now().millisecondsSinceEpoch}',
        amount: _getFinalShippingCost().toInt(),
        customerId: await SessionManager.getCustomerId() ?? '',
        customerName: 'Customer',
        customerEmail: 'customer@example.com',
        customerPhone: selectedAddress?['hp'] ?? '08123456789',
        itemDetails: [
          {
            'id': 'promo_exchange',
            'price': _getFinalShippingCost(),
            'quantity': 1,
            'name': 'Promo Exchange Shipping',
          }
        ],
        onTransactionFinished: (result) {
          Navigator.of(context).pop(); // Close loading

          if (PaymentService.isTransactionSuccess(result)) {
            // Payment successful, complete the point exchange
            _completeOrderWithPoints(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(PaymentService.getStatusMessage(result)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeOrderWithPoints(BuildContext context) async {
    // Validasi
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih alamat pengiriman'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedShipping == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih ekspedisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int userPoints = UserPointData.userPoints.value;

    if (userPoints < totalPoin) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Koin anda tidak mencukupi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Anda memiliki $userPoints koin, tetapi diperlukan $totalPoin koin untuk menukar produk ini.",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // Deduct points from user
    final newPoints = userPoints - totalPoin;
    final session = await SessionManager.getUserSession();
    final userId = session['id'];

    if (userId != null) {
      try {
        await ApiService.updateCostomer(userId, {'cos_poin': newPoints.toString()});
        UserPointData.setPoints(newPoints);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui poin: $e')),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StruckPesananPage(
          serviceType: 'shop',
          nama: selectedAddress?['nama'] ?? 'User',
          jumlahBarang: quantity,
          items: [
            {
              'merek': widget.produk['nama_produk'] ?? 'Produk',
              'device': widget.produk['deskripsi'] ?? 'Deskripsi',
              'seri': 'Poin: $totalPoin ($quantity x ${totalPoin ~/ quantity} poin)',
            },
          ],
          alamat: selectedAddress?['detailAlamat'] ?? 'Atur alamat anda di sini',
          totalHarga: '$totalPoin Poin',
        ),
      ),
    );
  }
}