import 'package:e_service/Beli/detail_produk.dart';
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Others/informasi.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 2;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  List<dynamic> produkList = [];
  bool isProductLoading = true;
  PageController? _pageController;
  int _currentBannerIndex = 1; // mulai dari banner ke-2
  late Timer _bannerTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 1, // mulai dari array ke-2
    );
    _pageController!.addListener(_onPageChanged);
    _startBannerTimer();
    _loadUserData();
    _loadProducts();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _bannerTimer.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController != null && _pageController!.hasClients) {
        int nextPage = _pageController!.page!.round() + 1;
        final int total = 5;

        _pageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        setState(() {
          _currentBannerIndex = nextPage % total;
        });
      }
    });
  }

  void _onPageChanged() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentBannerIndex = _pageController!.page?.round() ?? 0;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    final session = await SessionManager.getUserSession();
    final id = session['id'];
    if (id != null) {
      try {
        final data = await ApiService.getCostomerById(id);
        setState(() {
          userData = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
        }
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.getProduk();
      final filtered =
          data.where((p) {
            final gambar = p['gambar']?.toString().trim() ?? '';
            return gambar.isNotEmpty;
          }).toList();
      setState(() {
        produkList = filtered;
        isProductLoading = false;
      });
    } catch (e) {
      setState(() => isProductLoading = false);
    }
  }

  String formatRupiah(dynamic harga) {
    if (harga == null) return 'Rp 0';
    double number;
    if (harga is String) {
      number = double.tryParse(harga) ?? 0;
    } else if (harga is num) {
      number = harga.toDouble();
    } else {
      number = 0;
    }
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final nama = userData?['cos_nama'] ?? '-';
    final id = userData?['id_costomer'] ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
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
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoading ? _buildShimmerMemberCard() : _buildMemberCard(nama, id),
            const SizedBox(height: 24),
            SizedBox(height: 180, child: _buildBannerSlider()),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🔥 Hot Items',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child:
                  isProductLoading
                      ? _buildProductShimmer()
                      : produkList.isEmpty
                      ? const Center(
                        child: Text("Tidak ada produk dengan gambar"),
                      )
                      : _buildProductList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBannerSlider() {
    final List<String> banners = [
      'https://images.pexels.com/photos/3861972/pexels-photo-3861972.jpeg',
      'https://images.pexels.com/photos/380769/pexels-photo-380769.jpeg',
      'https://images.pexels.com/photos/3861973/pexels-photo-3861973.jpeg',
      'https://www.shutterstock.com/image-photo/panorama-focus-hand-holding-headset-600nw-2296039729.jpg',
      'https://images.pexels.com/photos/267350/pexels-photo-267350.jpeg',
    ];

    final List<String> titles = [
      'Diskon Service Komputer 50%',
      'Upgrade RAM & SSD',
      'Tips Perawatan Laptop',
      'Layanan Cepat & Profesional',
      'Tukar Poin untuk Servis',
    ];

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length * 1000, // efek looping panjang
            itemBuilder: (context, index) {
              final int realIndex = index % banners.length;

              return AnimatedBuilder(
                animation: _pageController!,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController!.position.haveDimensions) {
                    value = (_pageController!.page! - index).abs();
                    value = (1 - (value * 0.1)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(banners[realIndex]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titles[realIndex],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              String bannerText = '';
                              if (titles[realIndex] ==
                                  'Tips Perawatan Laptop') {
                                bannerText = '''
Tips dan Trik Merawat Laptop Ringan Agar Tidak Cepat Rusak

1. Jangan Membebani Laptop Anda Terlalu Berat
Salah satu cara paling sederhana untuk menjaga laptop tetap ringan adalah dengan tidak membebani laptop Anda terlalu berat. Jika Anda menjalankan banyak program berat atau membuka banyak tab browser sekaligus, laptop Anda akan bekerja lebih keras dan lebih panas. Hal ini dapat mengakibatkan kelebihan panas yang berpotensi merusak komponen dalam laptop Anda. Pastikan untuk menutup program yang tidak Anda gunakan dan mengelola aplikasi dengan bijak.

2. Gunakan Laptop pada Permukaan yang Rata dan Ventilasi yang Baik
Laptop yang digunakan pada permukaan yang datar dan keras akan membantu menjaga sirkulasi udara yang baik di sekitar laptop. Hindari meletakkan laptop Anda pada permukaan yang empuk seperti kasur atau bantal yang dapat menghalangi ventilasi udara, karena ini dapat menyebabkan laptop menjadi panas berlebihan. Gunakan alas laptop yang keras atau bantuan pendingin laptop jika diperlukan.

3. Bersihkan Laptop secara Berkala
Debu dan kotoran dapat mengumpul di dalam laptop dan mengganggu kinerja serta menyebabkan panas berlebihan. Bersihkan laptop secara berkala dengan menggunakan kompresor udara atau alat pembersih khusus untuk elektronik. Pastikan laptop dimatikan saat membersihkannya.

4. Hindari Guncangan dan Benturan
Guncangan dan benturan dapat merusak komponen dalam laptop Anda. Selalu pastikan laptop Anda ditempatkan dengan aman dan tidak terpapar risiko fisik yang berlebihan. Gunakan tas laptop yang dirancang khusus untuk melindunginya saat Anda bepergian.

5. Lakukan Update dan Backup Data Secara Teratur
Selalu perbarui sistem operasi dan perangkat lunak Anda secara berkala untuk menjaga keamanan dan kinerja laptop. Selain itu, lakukan backup data Anda secara teratur. Jika terjadi masalah atau kerusakan pada laptop, Anda akan memiliki cadangan data yang aman.

6. Hindari Paparan Suhu yang Ekstrem
Suhu yang ekstrem, baik terlalu panas maupun terlalu dingin, dapat merusak komponen dalam laptop. Hindari menggunakan laptop di tempat yang terlalu panas atau terlalu dingin. Selain itu, jangan biarkan laptop terkena sinar matahari langsung atau suhu ekstrem.

7. Gunakan Perangkat Lunak Antivirus dan Anti-Malware
Instal perangkat lunak antivirus dan anti-malware yang andal untuk melindungi laptop Anda dari serangan virus dan malware yang dapat merusak sistem Anda.

8. Matikan Laptop dengan Benar
Selalu matikan laptop Anda dengan benar daripada hanya mengaturnya ke mode sleep atau hibernate. Ini akan membantu menghindari masalah dengan sistem operasi dan perangkat keras.

Dengan mengikuti tips dan trik di atas, Anda dapat menjaga laptop Anda agar tetap ringan dan tidak cepat rusak. Merawat laptop dengan baik adalah investasi untuk menjaga kinerja laptop Anda dalam jangka panjang, sehingga Anda dapat terus menggunakannya dengan efisien dan tanpa masalah.
''';
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => InformasiPage(
                                        bannerImage: banners[realIndex],
                                        bannerTitle: titles[realIndex],
                                        bannerText: bannerText,
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Lihat Sekarang',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(String nama, String id) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1976D2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nama,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              id,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildShimmerMemberCard() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(width: 60, height: 60, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 16, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Container(width: 50, height: 14, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildProductShimmer() => ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: 3,
    itemBuilder:
        (context, index) => Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
  );

  Widget _buildProductList() => ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: produkList.length,
    itemBuilder: (context, index) {
      final produk = produkList[index];
      final gambar =
          (produk['gambar']?.toString().trim().replaceAll(',', '') ?? '');
      final nama = produk['nama_produk'] ?? 'Produk';
      final harga = produk['harga'] ?? 0;
      final rating = produk['rating'] ?? 0;
      final terjual = produk['terjual'] ?? 0;

      ImageProvider? imageProvider;
      if (gambar.isNotEmpty) {
        if (gambar.startsWith('http')) {
          imageProvider = NetworkImage(gambar);
        } else if (gambar.startsWith('assets/')) {
          imageProvider = AssetImage(gambar);
        }
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailProdukPage(produk: produk),
            ),
          );
        },
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[300],
                  image:
                      imageProvider != null
                          ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    imageProvider == null
                        ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white70,
                            size: 36,
                          ),
                        )
                        : null,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(harga),
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$rating | $terjual terjual',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade700,
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
      );
    },
  );

  Widget _buildBottomNavBar(BuildContext context) => BottomNavigationBar(
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
        setState(() => currentIndex = index);
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
      const BottomNavigationBarItem(
        icon: Icon(Icons.build_circle_outlined),
        label: 'Service',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        label: 'Beli',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
        icon:
            currentIndex == 3
                ? Image.asset('assets/image/promo.png', width: 24, height: 24)
                : Opacity(
                  opacity: 0.6,
                  child: Image.asset(
                    'assets/image/promo.png',
                    width: 24,
                    height: 24,
                  ),
                ),
        label: 'Promo',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ],
  );
}
