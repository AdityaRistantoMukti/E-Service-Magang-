import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_service/Beli/detail_produk.dart';
import 'package:flutter/foundation.dart';
import 'package:e_service/Beli/shop.dart' as shop;
import 'package:e_service/utils/product_cache.dart';
import 'package:e_service/Others/informasi.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/notification_service.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Others/tier_utils.dart';
import 'package:e_service/Others/user_point_data.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:e_service/api_services/payment_service.dart';
import 'package:e_service/artikel/cek_garansi.dart';
import 'package:e_service/artikel/kebersihan_alat.dart';
import 'package:e_service/artikel/poin_info.dart';
import 'package:e_service/artikel/tips.dart';
import 'package:e_service/config/api_config.dart';
import 'package:e_service/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:shimmer/shimmer.dart';



  class HomePage extends StatefulWidget {
    const HomePage({super.key, this.isFreshLogin = false});

    final bool isFreshLogin;

    @override
    State<HomePage> createState() => _HomePageState();
  }

  class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
    int currentIndex = 2;
    Map<String, dynamic>? userData;
    bool isLoading = true;
    List<dynamic> produkList = [];
    bool isProductLoading = true;
    
    // Store generated values untuk mencegah regenerasi
    Map<int, int> _productSoldCounts = {};
    Map<int, double> _productRatings = {};

    // non-nullable controller & timer (dijamin diinisialisasi di initState)
    late final PageController _pageController;
    int _currentBannerIndex = 1;
    late final Timer _bannerTimer;
    late final AnimationController _animationController;
    late final AnimationController _scaleAnimationController;
    late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 1, // mulai dari array ke-2
    );
    _pageController.addListener(_onPageChanged);
    _startBannerTimer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize scale animation for product cards
    _scaleAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
        CurvedAnimation(
          parent: _scaleAnimationController,
          curve: Curves.easeInOut,
        ),
      );

      _loadUserData();
      UserPointData.loadUserPoints();
      _loadProducts();
    }


    void _page_controller_init() {
      _pageController = PageController(viewportFraction: 0.85, initialPage: _currentBannerIndex);
    }

    @override
    void dispose() {
      // karena late final, pasti sudah diinisialisasi di initState
      _pageController.dispose();
      _bannerTimer.cancel();
      _animationController.dispose();
      _scaleAnimationController.dispose();
      super.dispose();
    }

     // Generate nilai terjual sekali saja untuk setiap produk
    int _getSoldCount(int index) {
      if (!_productSoldCounts.containsKey(index)) {
        final random = Random();
        _productSoldCounts[index] = 10 + random.nextInt(90); // 10-99 terjual
      }
      return _productSoldCounts[index]!;
    }
    
  // Generate rating sekali saja untuk setiap produk
  double _getProductRating(int index) {
    if (!_productRatings.containsKey(index)) {
      final random = Random();
      _productRatings[index] = 4.0 + (random.nextDouble() * 1.0); // 4.0-5.0
    }
    return _productRatings[index]!;
  }

    // Helper untuk generate badge status
  String? _getProductBadge(int index) {
    if (index == 0) return 'HOT';
    if (index < 3) return 'BEST SELLER';
    if (index < 5) return 'NEW';
    return null;
  }

    // Helper untuk get badge color
  Color _getBadgeColor(String? badge) {
    switch (badge) {
      case 'HOT':
        return Colors.red;
      case 'BEST SELLER':
        return Colors.orange;
      case 'NEW':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
    // =======================
    // 🔹 MIDTRANS INIT - REMOVED
    // =======================
    // Midtrans SDK initialization removed - now using redirect_url approach

    // =======================
    // 🔹 UTIL FUNCTIONS
    // =======================

    String getFirstImageUrl(dynamic gambarField) {
      if (gambarField == null) return '';

      if (gambarField is List && gambarField.isNotEmpty) {
        return '${ApiConfig.storageBaseUrl}${gambarField.first}';
      }

      if (gambarField is String && gambarField.isNotEmpty) {
        try {
          if (gambarField.contains('[')) {
            final List list = List<String>.from(jsonDecode(gambarField));
            if (list.isNotEmpty) {
              return '${ApiConfig.storageBaseUrl}${list.first}';
            }
          }
        } catch (_) {}
        return '${ApiConfig.storageBaseUrl}$gambarField';
      }

      return '';
    }

    ImageProvider? getImageProvider(dynamic gambarField) {
      final url = getFirstImageUrl(gambarField);
      if (url.isEmpty) return null;
      return NetworkImage(url);
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
      // Multiply by 10 to correct the price display
      number *= 10;
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(number);
    }

    // =======================
    // 🔹 LOAD DATA
    // =======================

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
          // Show welcome notification if fresh login
          if (widget.isFreshLogin && mounted) {
            _showWelcomeNotification();
          }
        } catch (e) {
          setState(() => isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
          }
        }
      } else {
        setState(() => isLoading = false);
      }
    }

    Future<void> _loadProducts() async {
      try {
        // Check if products are already cached from shop.dart
        if (ProductCache.productsLoaded && ProductCache.cachedProdukList.isNotEmpty) {
          // Use cached products
          final filtered = ProductCache.cachedProdukList.where((p) {
            final gambar = p['gambar']?.toString().trim() ?? '';
            return gambar.isNotEmpty;
          }).toList();
          setState(() {
            produkList = filtered;
            isProductLoading = false;
          });
        } else {
          // Load products fresh and cache them
          final data = await ApiService.getProduk();
          final filtered = data.where((p) {
            final gambar = p['gambar']?.toString().trim() ?? '';
            return gambar.isNotEmpty;
          }).toList();
          setState(() {
            produkList = filtered;
            isProductLoading = false;
          });
          // Also cache for shop.dart
          ProductCache.setProducts(filtered);
        }
      } catch (e) {
        setState(() => isProductLoading = false);
      }
    }

   void _showWelcomeNotification() async {
  if (!mounted) return;
  final nama = userData?['cos_nama'] ?? 'Pengguna';

  await NotificationService.addNotification(
    NotificationModel(
      title: 'Welcome',
      subtitle: 'Halooo, $nama 👋',
      icon: Icons.waving_hand,
      color: Colors.green,
      textColor: Colors.white,
      timestamp: DateTime.now(),
    ),
  );

  late OverlayEntry overlayEntry;
  final animationController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );
  final curvedAnimation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOutBack,
  );

  
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1.2),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: GestureDetector(
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (details.velocity.pixelsPerSecond.dx.abs() > 200) {
                    HapticFeedback.lightImpact();
                    animationController.reverse().then((_) {
                      overlayEntry.remove();
                    });
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.waving_hand,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Welcome!',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Halooo, $nama 👋',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            animationController.reverse().then((_) {
                              overlayEntry.remove();
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );


  Overlay.of(context).insert(overlayEntry);

  // Jalankan animasi muncul
  animationController.forward();
  HapticFeedback.lightImpact();
  // Hilang otomatis setelah 3 detik
  Timer(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      animationController.reverse().then((_) {
        overlayEntry.remove();
        animationController.dispose();
      });
    }
  });
}

  // =======================
  // 🔹 BANNER LOOP HALUS
  // =======================

  void _onPageChanged() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentBannerIndex = _pageController.page?.round() ?? 0;
          });
        }
      });
    }
      void _startBannerTimer() {
      _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_pageController.hasClients) {
          int nextPage = _pageController.page!.round() + 1;
          final int total = 5;

          _pageController.animateToPage(
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


  Widget _buildBannerSlider() {
    final List<String> banners = [
      'assets/image/banner/garansi.jpg',
      'assets/image/banner/tips.png',
      'assets/image/banner/kebersihan.jpg',
      'assets/image/banner/points.png',
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
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.1)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image:
                          banners[realIndex].startsWith('assets/')
                              ? AssetImage(banners[realIndex])
                              : NetworkImage(banners[realIndex]),
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
                          ElevatedButton(
                            onPressed: () {
                              if (realIndex == 0) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const CekGaransiPage(),
                                  ),
                                );
                              } else if (realIndex == 1) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TipsPage(),
                                  ),
                                );
                              } else if (realIndex == 2) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const KebersihanAlatPage(),
                                  ),
                                );
                              } else if (realIndex == 3) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PoinInfoPage(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Lihat Sekarang',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
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



    // =======================
    // 🔹 UI BUILD
    // =======================

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
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
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
              const SizedBox(height: 10),
              SizedBox(height: 180, child: _buildBannerSlider()),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🔥 Hot Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: isProductLoading ? _buildProductShimmer() : produkList.isEmpty ? const Center(child: Text("Tidak ada produk dengan gambar")) : _buildEnhancedProductList(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServicePage()));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const shop.MarketplacePage()));
            } else if (index == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TukarPoinPage()));
            } else if (index == 4) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/image/promo.png', width: 24, height: 24, color: Colors.white70),
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

    // =======================
    // 🔹 WIDGET HELPERS
    // =======================
    


  // Ganti bagian _buildMemberCard di home.dart Anda dengan code ini:

  Widget _buildMemberCard(String nama, String id) {
    final foto = userData?['cos_gambar'];

    return ValueListenableBuilder<int>(
      valueListenable: UserPointData.userPoints,
      builder: (context, points, _) {
        final tierInfo = getTierInfo(points);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: tierInfo.decoration,
          child: Stack(
            children: [
              // Decorative circles in background
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    
                  ),
                ),
              ),
              
              // Main content
              Row(
                children: [
                  // Profile picture with glow effect
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (foto != null && foto.toString().isNotEmpty)
                          ? Image.network(
                              "${ApiConfig.storageBaseUrl}$foto",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(

                                  child: Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                );
                              },
                            )
                          : Container(
                              
                              child: Icon(
                                Icons.person,
                                size: 36,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nama,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),                         
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            id,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Points section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/image/coin.png',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$points',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }



    Widget _buildShimmerMemberCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
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


    
  Widget _buildProductShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder:
          (context, index) => Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
    );
  }
  
  // Enhanced Product Card - Tanpa diskon
  Widget _buildImageWithFallback(
    dynamic gambarField,
    double height,
    BoxFit fit,
    BorderRadius borderRadius, {
    int currentIndex = 0,
  }) {
    print('🖼️ [IMAGE] Building image with gambarField: $gambarField (type: ${gambarField.runtimeType})');

    // Cek apakah gambarField null atau empty
    if (gambarField == null || (gambarField is String && gambarField.isEmpty)) {
      print('🖼️ [IMAGE] gambarField is null or empty, showing fallback');
      return _buildFallbackImageContainer(height, borderRadius);
    }

    String imageUrl = '';

    // Prioritas: gunakan gambar_url jika tersedia (dari accessor backend)
    if (gambarField is Map && gambarField.containsKey('gambar_url')) {
      final gambarUrlField = gambarField['gambar_url'];
      print('🖼️ [IMAGE] Found gambar_url in map: $gambarUrlField');

      if (gambarUrlField is List && gambarUrlField.isNotEmpty) {
        // Jika array URL dari backend
        if (currentIndex < gambarUrlField.length) {
          imageUrl = gambarUrlField[currentIndex].toString();
        } else {
          imageUrl = gambarUrlField[0].toString();
        }
      } else if (gambarUrlField is String && gambarUrlField.isNotEmpty) {
        // Jika single URL string
        imageUrl = gambarUrlField;
      } else {
        // Fallback ke field gambar biasa
        final gambarBiasa = gambarField['gambar'];
        if (gambarBiasa != null) {
          return _buildImageWithFallback(gambarBiasa, height, fit, borderRadius, currentIndex: currentIndex);
        }
        return _buildFallbackImageContainer(height, borderRadius);
      }
    }
    // Jika gambarField adalah array (dari gambar_url accessor)
    else if (gambarField is List && gambarField.isNotEmpty) {
      print('🖼️ [IMAGE] gambarField is List with ${gambarField.length} items');
      // Jika array, ambil index yang diminta
      if (currentIndex < gambarField.length) {
        imageUrl = gambarField[currentIndex].toString();
      } else {
        imageUrl = gambarField[0].toString();
      }
    }
    // Jika gambarField adalah string (URL lengkap atau path)
    else if (gambarField is String && gambarField.isNotEmpty) {
      print('🖼️ [IMAGE] gambarField is String: $gambarField');

      // Check if string contains multiple URLs separated by commas
      if (gambarField.contains(',')) {
        final urlList = gambarField.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        print('🖼️ [IMAGE] String contains commas, split into ${urlList.length} URLs');
        if (urlList.isNotEmpty) {
          if (currentIndex < urlList.length) {
            imageUrl = urlList[currentIndex];
          } else {
            imageUrl = urlList[0];
          }
        } else {
          return _buildFallbackImageContainer(height, borderRadius);
        }
      } else {
        imageUrl = gambarField;
      }

      // Jika belum lengkap, tambahkan base URL
      if (!imageUrl.startsWith('http')) {
        if (imageUrl.contains('assets/image/')) {
          imageUrl = ApiConfig.storageBaseUrl + imageUrl;
        } else {
          imageUrl = ApiConfig.storageBaseUrl + 'assets/image/' + imageUrl;
        }
        print('🖼️ [IMAGE] Added base URL, final URL: $imageUrl');
      } else {
        print('🖼️ [IMAGE] URL already complete: $imageUrl');
      }
    } else {
      print('🖼️ [IMAGE] gambarField type not recognized, showing fallback');
      return _buildFallbackImageContainer(height, borderRadius);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        height: height,
        width: double.infinity,
        placeholder: (context, url) => Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade100, Colors.grey.shade200],
            ),
          ),
          child: Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, error, stackTrace) {
          print('❌ [IMAGE] Error loading image: $error');
          print('❌ [IMAGE] Failed URL: $imageUrl');

          // Jika gambarField adalah array dan masih ada gambar lain, coba gambar berikutnya
          if (gambarField is List && currentIndex + 1 < gambarField.length) {
            print('🔄 [IMAGE] Trying next image in array');
            return _buildImageWithFallback(
              gambarField,
              height,
              fit,
              borderRadius,
              currentIndex: currentIndex + 1,
            );
          }

          return _buildFallbackImageContainer(height, borderRadius);
        },
      ),
    );
  }

  Widget _buildFallbackImageContainer(double height, BorderRadius borderRadius) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 4),
          Text('No Image',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildEnhancedProductCard({
    required Map<String, dynamic> produk,
    required int index,
  }) {
    final nama = produk['nama_produk'] ?? 'Produk';
    final harga = produk['harga'] ?? 0;
    final rating = _getProductRating(index);
    final terjual = _getSoldCount(index);
    final badge = _getProductBadge(index);

    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive dimensions - adjust for better fit
    final cardWidth = screenWidth * 0.42; // Slightly smaller: 42% of screen width
    final imageHeight = cardWidth * 0.7; // Adjusted aspect ratio for image
    final contentHeight = 100.0; // Fixed content height to prevent overflow
    final cardHeight = imageHeight + contentHeight; // Total card height

    // Responsive text sizes
    final titleFontSize = screenWidth < 360 ? 11.0 : 12.0;
    final priceFontSize = screenWidth < 360 ? 12.0 : 13.0;
    final ratingFontSize = screenWidth < 360 ? 9.0 : 10.0;
    final soldFontSize = screenWidth < 360 ? 9.0 : 10.0;

    return GestureDetector(
      onTapDown: (_) => _scaleAnimationController.forward(),
      onTapUp: (_) => _scaleAnimationController.reverse(),
      onTapCancel: () => _scaleAnimationController.reverse(),
      onTap: () {
        _scaleAnimationController.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProdukPage(produk: produk),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Container with Badges
                  Stack(
                    children: [
                      Container(
                        height: imageHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.grey.shade50, Colors.white],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: _buildImageWithFallback(
                            produk['gambar'],
                            imageHeight - 12, // Subtract padding
                            BoxFit.contain,
                            BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      // Badge
                      if (badge != null)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getBadgeColor(badge),
                                  _getBadgeColor(badge).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: _getBadgeColor(badge).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth < 360 ? 7 : 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Content - Flexible height to prevent overflow
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Product Name - Allow more flexible height
                          Flexible(
                            flex: 2,
                            child: Text(
                              nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                height: 1.1,
                              ),
                            ),
                          ),

                          // Price Section
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatRupiah(harga),
                                  style: GoogleFonts.poppins(
                                    fontSize: priceFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: screenWidth < 360 ? 12 : 14,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),

                          // Rating and Sold - Fixed height section
                          SizedBox(
                            height: 20, // Fixed height for rating/sold row
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: screenWidth < 360 ? 8 : 10,
                                        color: Colors.amber[600],
                                      ),
                                      const SizedBox(width: 1),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          fontSize: ratingFontSize,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$terjual terjual',
                                    style: GoogleFonts.poppins(
                                      fontSize: soldFontSize,
                                      color: Colors.grey[500],
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
            ),
          );
        },
      ),
    );
  }
   
  // Enhanced Product List
  Widget _buildEnhancedProductList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: produkList.length,
      itemBuilder: (context, index) {
        final produk = Map<String, dynamic>.from(produkList[index]);
        return _buildEnhancedProductCard(produk: produk, index: index);
      },
    );
  }        
}


