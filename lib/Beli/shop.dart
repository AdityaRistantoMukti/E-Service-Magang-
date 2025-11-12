import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_service/Beli/detail_produk.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:e_service/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

class ProductCache {
  static bool _productsLoaded = false;
  static List<dynamic> _cachedProdukList = [];

  static bool get productsLoaded => _productsLoaded;
  static List<dynamic> get cachedProdukList => _cachedProdukList;

  static void setProducts(List<dynamic> products) {
    _cachedProdukList = products;
    _productsLoaded = true;
  }

  static void clearCache() {
    _productsLoaded = false;
    _cachedProdukList = [];
  }
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with TickerProviderStateMixin {
  int currentIndex = 1;
  String? selectedBrand;
  List<dynamic> _produkList = [];
  List<dynamic> _filteredProduk = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> brandsData = [
    {'name': 'Asus', 'logo': 'asus_logo.png', 'needsWhite': true},
    {'name': 'Advan', 'logo': 'advan_logo.png', 'needsWhite': true},
    {'name': 'MSI', 'logo': 'msi_logo.png', 'needsWhite': true},
    {'name': 'HP', 'logo': 'hp_logo.png', 'needsWhite': true},
    {'name': 'Canon', 'logo': 'canon_logo.png', 'needsWhite': true},
    {'name': 'Epson', 'logo': 'epson_logo.png', 'needsWhite': true},
    {'name': 'Legion', 'logo': 'lenovo_logo.png', 'needsWhite': true},
    {'name': 'Infinix', 'logo': 'infinix_logo.png', 'needsWhite': true},
    {'name': 'Zyrex', 'logo': 'zyrex_logo.png', 'needsWhite': true},
    {'name': 'Axio', 'logo': 'axioo_logo.png', 'needsWhite': true},
  ];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Preload logos setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadLogos();
    });

    // Load products only if not already loaded
    if (!ProductCache.productsLoaded) {
      _loadProduk();
    } else {
      // Use cached products
      _produkList = ProductCache.cachedProdukList;
      _filteredProduk = _getFilteredList();
      _isLoading = false;
      setState(() {});
    }
  }

  // Preload semua logo untuk performa lebih baik
  void _preloadLogos() {
    for (var brand in brandsData) {
      if (brand['logo'] != null) {
        final logo = AssetImage('assets/image/${brand['logo']}');
        precacheImage(logo, context).catchError((error) {
          debugPrint('Error preloading ${brand['logo']}: $error');
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProduk() async {
    try {
      final produk = await ApiService.getProduk();
      print('📦 [SHOP] Loaded ${produk.length} products');
      // Debug: Print first product to see structure
      if (produk.isNotEmpty) {
        print('📦 [SHOP] First product: ${produk[0]}');
        print('📦 [SHOP] First product gambar: ${produk[0]['gambar']}');
        print('📦 [SHOP] First product gambar_url: ${produk[0]['gambar_url']}');
      }
      if (mounted) {
        setState(() {
          _produkList = produk;
          ProductCache.setProducts(produk);
          _filteredProduk = _getFilteredList(); // Langsung assign tanpa setState di dalam
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error load produk: $e');
    }
  }

  // PERBAIKAN: Pisahkan logic filter dari setState
  List<dynamic> _getFilteredList() {
    List<dynamic> filtered = List.from(_produkList);
    
    // Filter berdasarkan brand
    if (selectedBrand != null) {
      final brandUpper = selectedBrand!.toUpperCase();
      filtered = filtered.where((p) {
        final apiBrand = (p['brand'] ?? '').toString().toUpperCase();
        final namaProduk = (p['nama_produk'] ?? '').toString().toUpperCase();
        return apiBrand == brandUpper || namaProduk.contains(brandUpper);
      }).toList();
    }
    
    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => 
        (p['nama_produk'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }
    
    // Sort list
    _sortProdukList(filtered);
    
    return filtered;
  }

  // PERBAIKAN: Method ini hanya untuk update state
  void _applyFilters() {
    setState(() {
      _filteredProduk = _getFilteredList();
    });
  }

  void _sortProdukList(List<dynamic> list) {
    list.sort((a, b) {
      final aHasImage = a['gambar_url'] != null && a['gambar_url'].toString().isNotEmpty;
      final bHasImage = b['gambar_url'] != null && b['gambar_url'].toString().isNotEmpty;
      if (aHasImage && !bHasImage) return -1;
      if (!aHasImage && bHasImage) return 1;
      final hargaA = double.tryParse(a['harga'].toString()) ?? 0.0;
      final hargaB = double.tryParse(b['harga'].toString()) ?? 0.0;
      return hargaB.compareTo(hargaA);
    });
  }

  String formatRupiah(dynamic harga) {
    final double number = double.tryParse(harga.toString()) ?? 0.0;
    final double correctedNumber = number * 10;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(correctedNumber);
  }

  double _getRatingAsDouble(dynamic rating) {
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 4.5;
    return 4.5;
  }

  int _getSoldAsInt(dynamic sold) {
    if (sold is int) return sold;
    if (sold is double) return sold.toInt();
    if (sold is String) return int.tryParse(sold) ?? Random().nextInt(100);
    return Random().nextInt(100);
  }

  String? _getProductBadge(int index) {
    if (index == 0) return 'HOT';
    if (index < 3) return 'BEST SELLER';
    if (index < 5) return 'NEW';
    return null;
  }

  Color _getBadgeColor(String? badge) {
    switch (badge) {
      case 'HOT':
        return const Color(0xFFFF6B6B);
      case 'BEST SELLER':
        return const Color(0xFFFFB84D);
      case 'NEW':
        return const Color(0xFF51CF66);
      default:
        return Colors.blue;
    }
  }

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
        String baseUrl = ApiConfig.storageBaseUrl;
        if (imageUrl.contains('assets/image/')) {
          imageUrl = baseUrl + imageUrl;
        } else {
          imageUrl = baseUrl + 'assets/image/' + imageUrl;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 24),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage())),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
              onRefresh: _loadProduk,
              color: Colors.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSearchBar(),
                    ),
                    const SizedBox(height: 16),
                    _buildBrandList(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildContentBody(),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBrandList() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: brandsData.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final brand = brandsData[index];
          return _buildBrandChip(
            name: brand['name'],
            logoAsset: brand['logo'],
            needsWhite: brand['needsWhite'] ?? true,
          );
        },
      ),
    );
  }

  Widget _buildBrandChip({
    required String name,
    String? logoAsset,
    required bool needsWhite,
  }) {
    final bool isSelected = (selectedBrand == name);
    final bool hasLogo = logoAsset != null;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBrand = isSelected ? null : name;
        });
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.withOpacity(0.4)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Center(
          child: hasLogo
              ? SizedBox(
                  height: 26,
                  width: 60,
                  child: _buildBrandLogo(
                    logoAsset: logoAsset,
                    isSelected: isSelected,
                    needsWhite: needsWhite,
                    brandName: name,
                  ),
                )
              : Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo({
    required String logoAsset,
    required bool isSelected,
    required bool needsWhite,
    required String brandName,
  }) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected && needsWhite ? Colors.white : Colors.transparent,
        isSelected && needsWhite ? BlendMode.srcIn : BlendMode.dst,
      ),
      child: Image.asset(
        'assets/image/$logoAsset',
        fit: BoxFit.contain,
        cacheWidth: 120,
        errorBuilder: (context, error, stack) {
          debugPrint('Error loading logo $logoAsset: $error');
          return Text(
            brandName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade800),
              decoration: InputDecoration(
                hintText: 'Cari produk impianmu...',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
              onPressed: () {
                _searchController.clear();
                _searchQuery = '';
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContentBody() {
    if (_searchQuery.isNotEmpty) return _buildSearchResultsList();
    if (selectedBrand != null) {
      return _buildEnhancedProductGrid(
          list: _filteredProduk, title: 'Produk ${selectedBrand!}');
    }
    return Column(
      children: [
        _buildEnhancedProductList(title: '🔥 Produk Terlaris'),
        const SizedBox(height: 28),
        _buildEnhancedProductList(
            title: '🖱️ Koleksi Mouse', filterKeyword: 'Mouse'),
        const SizedBox(height: 28),
        _buildEnhancedProductGrid(
            list: _filteredProduk, title: '✨ Semua Produk'),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Text(
          'Lihat Semua',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.blue.shade600),
      ],
    );
  }

  Widget _buildEnhancedProductList(
      {required String title, String? filterKeyword}) {
    List<dynamic> produkList = List.from(_filteredProduk);
    if (filterKeyword != null) {
      produkList = produkList
          .where((p) => (p['nama_produk'] ?? '')
              .toString()
              .toLowerCase()
              .contains(filterKeyword.toLowerCase()))
          .toList();
    }
    if (produkList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: produkList.length > 5 ? 5 : produkList.length,
            itemBuilder: (context, index) => _buildEnhancedProductCard(
                produk: produkList[index], index: index),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProductGrid(
      {required List<dynamic> list, required String title}) {
    if (list.isEmpty && selectedBrand == null && _searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 70, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    selectedBrand != null
                        ? 'Tidak ada produk untuk brand ini'
                        : 'Tidak ada produk ditemukan',
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.7,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) => _buildEnhancedProductCard(
                produk: list[index], index: index, isGrid: true),
          ),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    if (_filteredProduk.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Tidak ditemukan untuk "$_searchQuery"',
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return _buildEnhancedProductGrid(
        list: _filteredProduk, title: 'Hasil Pencarian');
  }

  Widget _buildEnhancedProductCard({
    required Map<String, dynamic> produk,
    required int index,
    bool isGrid = false,
  }) {
    final badge = _getProductBadge(index);
    final rating = _getRatingAsDouble(produk['rating']);
    final sold = _getSoldAsInt(produk['terjual']);

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        _animationController.reverse();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DetailProdukPage(produk: produk)));
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: isGrid ? double.infinity : 190,
            margin: EdgeInsets.only(right: isGrid ? 0 : 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: isGrid ? 120 : 135,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey.shade50, Colors.grey.shade100],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildImageWithFallback(
                          produk['gambar'],
                          isGrid ? 120 : 135,
                          BoxFit.contain,
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getBadgeColor(badge),
                                _getBadgeColor(badge).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: _getBadgeColor(badge).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          produk['nama_produk'] ?? 'Produk Tanpa Nama',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: isGrid ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatRupiah(produk['harga']),
                          style: GoogleFonts.poppins(
                            fontSize: isGrid ? 14 : 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 16, color: Colors.amber.shade600),
                            const SizedBox(width: 5),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 14,
                              width: 1.5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                '$sold terjual',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade50,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade50,
                      child: Container(
                        width: 160,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade50,
                        child: Container(
                          width: 190,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ServicePage()));
              break;
            case 2:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const HomePage()));
              break;
            case 3:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TukarPoinPage()));
              break;
            case 4:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfilePage()));
              break;
            default:
              setState(() => currentIndex = index);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          letterSpacing: 0.2,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            activeIcon: Icon(Icons.build_circle),
            label: 'Service',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Beli',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/promo.png',
              width: 24,
              height: 24,
              color: Colors.grey.shade400,
            ),
            activeIcon: Image.asset(
              'assets/image/promo.png',
              width: 24,
              height: 24,
              color: Colors.blue.shade700,
            ),
            label: 'Promo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}