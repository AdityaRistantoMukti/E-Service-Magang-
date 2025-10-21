  import 'package:e_service/Beli/shop.dart';
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
    int _currentBannerIndex = 0;

    @override
    void initState() {
      super.initState();
      _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
      _pageController!.addListener(_onPageChanged);
      _loadUserData();
      _loadProducts();
    }

    @override
    void dispose() {
      _pageController?.dispose();
      super.dispose();
    }

    void _onPageChanged() {
      // Gunakan SchedulerBinding untuk menghindari setState selama build
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
      final id = session['id']; // ini 'id_costomer'
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat data: $e')),
            );
          }
        }
      } else {
        setState(() => isLoading = false);
      }
    }

    Future<void> _loadProducts() async {
      try {
        final data = await ApiService.getProduk();
        final filtered = data.where((p) {
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
          
          // Pastikan kita punya angka
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
            decimalDigits: 0, // kalau mau tanpa desimal
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

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Member Card
              isLoading ? _buildShimmerMemberCard() : _buildMemberCard(nama, id),
              const SizedBox(height: 24),          
              // 🔹 Banner Slider Dummy
              SizedBox(
                height: 180, // Sedikit lebih tinggi untuk efek
                child: _buildBannerSlider(),
              ),
              const SizedBox(height: 20),

              // 🔹 Hot Items
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
              child: isProductLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
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
                    )
                  : produkList.isEmpty
                      ? const Center(child: Text("Tidak ada produk dengan gambar"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: produkList.length,
                          itemBuilder: (context, index) {
                            final produk = produkList[index];
                            final gambar = (produk['gambar']?.toString().trim().replaceAll(',', '') ?? '');
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

                            return Container(
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
                                      borderRadius:
                                          const BorderRadius.vertical(top: Radius.circular(12)),
                                      color: Colors.grey[300],
                                      image: imageProvider != null
                                          ? DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: imageProvider == null
                                        ? const Center(
                                            child: Icon(Icons.image_outlined,
                                                color: Colors.white70, size: 36),
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
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 14),
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
                            );
                          },
                        ),
                      ),
            ],
          ),
        ),

        // 🔹 Bottom Navigation Bar
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
              icon: currentIndex == 3
                  ? Image.asset('assets/image/promo.png', width: 24, height: 24)
                  : Opacity(
                      opacity: 0.6,
                      child: Image.asset('assets/image/promo.png', width: 24, height: 24),
                    ),
              label: 'Promo',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      );
    }
    Widget _buildBannerSlider() {
      if (_pageController == null) {
        return const Center(child: CircularProgressIndicator());
      }

      // Gambar banner online bertema komputer/service
      final List<String> banners = [
        'https://images.pexels.com/photos/3861972/pexels-photo-3861972.jpeg', // Servis komputer
        'https://images.pexels.com/photos/380769/pexels-photo-380769.jpeg', // Perbaikan laptop
        'https://images.pexels.com/photos/3861973/pexels-photo-3861973.jpeg', // Teknisi komputer
        'https://www.shutterstock.com/image-photo/panorama-focus-hand-holding-headset-600nw-2296039729.jpg', // Workspace komputer
        'https://images.pexels.com/photos/267350/pexels-photo-267350.jpeg', // Servis hardware
      ];

      final List<String> titles = [
        'Diskon Service Komputer 50%',
        'Upgrade RAM & SSD',
        'Promo Perbaikan Laptop',
        'Layanan Cepat & Profesional',
        'Tukar Poin untuk Servis',
      ];

      return Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                // Hitung scale berdasarkan jarak dari halaman saat ini
                double scale = 0.9;
                if (_pageController!.hasClients) {
                  double currentPage = _pageController!.page ?? 0.0;
                  scale = 0.9 + 0.1 * (1.0 - (currentPage - index).abs().clamp(0.0, 1.0));
                }

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(banners[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
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
                              titles[index],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                height: 8,
                width: _currentBannerIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == index ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      );
    }


    // Member Card (Data)
    Widget _buildMemberCard(String nama, String id) {
      return Container(
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
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Shimmer Member Card
    Widget _buildShimmerMemberCard() {
      return Shimmer.fromColors(
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
              Container(
                width: 60,
                height: 60,
                color: Colors.grey[400],
              ),
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
    }

    // Shimmer Grid Item
    Widget _buildShimmerGridItem() {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }