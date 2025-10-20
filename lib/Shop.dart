import 'package:e_service/home.dart';
import 'package:e_service/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'service.dart';
import 'promo.dart';
import 'profile.dart';
import 'notifikasi.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  int currentIndex = 1;
  String? selectedBrand;
  List<dynamic> _produkList = [];
  List<dynamic> _filteredProduk = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProduk();
  }

  Future<void> _loadProduk() async {
    try {
      final produk = await ApiService.getProduk();
      setState(() {
        _produkList = produk;
        _filteredProduk = List.from(produk);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error load produk: $e');
    }
  }

  void _searchProduk(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_produkList);

    if (selectedBrand != null && selectedBrand!.isNotEmpty) {
      final brandUpper = selectedBrand!.toUpperCase();
      filtered = filtered.where((p) {
        final nama = (p['nama_produk'] ?? '').toString().toUpperCase();
        return nama.contains(brandUpper);
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final nama = (p['nama_produk'] ?? '').toString().toLowerCase();
        return nama.contains(q);
      }).toList();
    }

    // Urutkan harga dari tertinggi
    filtered.sort((a, b) {
      final hargaA = double.tryParse(a['harga'].toString()) ?? 0.0;
      final hargaB = double.tryParse(b['harga'].toString()) ?? 0.0;
      return hargaB.compareTo(hargaA);
    });

    setState(() {
      _filteredProduk = filtered;
    });
  }

  String formatRupiah(dynamic harga) {
    final double number = double.tryParse(harga.toString()) ?? 0.0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  @override
  Widget build(BuildContext context) {
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
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
        ],
      ),

      // 🔹 Body
      body: _isLoading
          ? _buildShimmerLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandList(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  //  Search aktif
                  if (_searchQuery.isNotEmpty) ...[                                        
                    _filteredProduk.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Tidak ditemukan untuk "$_searchQuery"',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          )
                        : _buildSearchResultsList(),
                  ]
                  // 🔹 Tidak sedang search
                  else if (selectedBrand == null) ...[
                    _buildSectionTitle('Teratas'),
                    const SizedBox(height: 8),
                    _buildProductList(), // default: tampil semua

                    const SizedBox(height: 16),
                    _buildSectionTitle('Mouse'),
                    const SizedBox(height: 8),
                    _buildProductList(), // kamu bisa ubah filter khusus kategori jika ada field kategori

                    const SizedBox(height: 16),
                    _buildSectionTitle('Lainnya'),
                    const SizedBox(height: 8),
                    _buildProductList(),
                  ] else ...[
                    _buildSectionTitle('Produk ${selectedBrand!}'),
                    const SizedBox(height: 8),
                    _buildProductList(selectedBrand),
                  ],
                ],
              ),
            ),

      // 🔹 Bottom Navigation
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ======================== 🔹 COMPONENTS ========================

  Widget _buildBrandList() {
    final brands = [
      'Advan',
      'MSI',
      'HP',
      'Axio',
      'Legion',
      'Canon',
      'Epson',
      'IBOX',
      'AIO',
      'Tecno',
      'Infinix',
      'Zyrex'
    ];

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: brands.map((b) => _buildBrandItem(b)).toList(),
      ),
    );
  }

  // <-- INI METHOD YANG KAMU BUTUHKAN (ditambahkan)
  Widget _buildBrandItem(String name) {
    final bool isSelected = (selectedBrand != null && selectedBrand == name);

    return GestureDetector(
      onTap: () {
        setState(() {
          // toggle selection
          if (isSelected) {
            selectedBrand = null;
          } else {
            selectedBrand = name;
          }
          _applyFilters();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              onChanged: _searchProduk,
            ),
          ),
          const Icon(Icons.search, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    );
  }

  Widget _buildProductList([String? brand]) {
  List<Map<String, dynamic>> produkList =
      List<Map<String, dynamic>>.from(_produkList);

  // Filter berdasarkan brand jika ada
  if (brand != null && brand.isNotEmpty) {
    final bUpper = brand.toUpperCase();
    produkList = produkList
        .where((p) =>
            (p['nama_produk'] ?? '').toString().toUpperCase().contains(bUpper))
        .toList();
  }

  // Urutkan berdasarkan harga tertinggi
  produkList.sort((a, b) {
    final hargaA = double.tryParse(a['harga'].toString()) ?? 0;
    final hargaB = double.tryParse(b['harga'].toString()) ?? 0;
    return hargaB.compareTo(hargaA);
  });

  if (produkList.isEmpty) {
    return const Center(child: Text('Tidak ada produk'));
  }

  // 🔹 Jika brand dipilih → tampil grid 2 kolom
  if (brand != null && brand.isNotEmpty) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // dua kolom
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: produkList.length,
      itemBuilder: (context, index) {
        final produk = produkList[index];
        return Container(
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
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: Colors.white70, size: 32),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk['nama_produk'] ?? 'Tanpa Nama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(produk['harga']),
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
                          '${produk['rating'] ?? 0} | ${produk['terjual'] ?? 0} terjual',
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
    );
  }

  // 🔹 Jika tidak ada brand → tampil horizontal (default)
  return SizedBox(
    height: 240,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: produkList.length,
      itemBuilder: (context, index) {
        final produk = produkList[index];
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
                  color: Colors.grey[400],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: Colors.white70, size: 36),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk['nama_produk'] ?? 'Tanpa Nama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(produk['harga']),
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
                          '${produk['rating'] ?? 0} | ${produk['terjual'] ?? 0} terjual',
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
  );
}


  Widget _buildSearchResultsList() {
  if (_filteredProduk.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Tidak ditemukan untuk "$_searchQuery"',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, // tampil 3 kolom
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.6,
    ),
    itemCount: _filteredProduk.length,
    itemBuilder: (context, index) {
      final produk = _filteredProduk[index];
      return Container(
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
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined,
                    color: Colors.white70, size: 28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk['nama_produk'] ?? 'Tanpa Nama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(produk['harga']),
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}


    Widget _buildShimmerLoading() {
    // helper: shimmer pill (brand)
    Widget _shimmerBrandPill() {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          width: 90,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // helper: one horizontal shimmer card (same shape as product card)
    Widget _shimmerProductCard({double width = 160, double heightImg = 110}) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: width,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image area
              Container(
                height: heightImg,
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 100, color: Colors.grey[350]),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 70, color: Colors.grey[350]),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 120, color: Colors.grey[350]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // helper: one grid shimmer tile (for brand-selected grid)
    Widget _shimmerGridTile() {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(height: 100, decoration: BoxDecoration(color: Colors.grey[350], borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
              const SizedBox(height: 8),
              Container(height: 12, width: 100, color: Colors.grey[350]),
              const SizedBox(height: 6),
              Container(height: 12, width: 60, color: Colors.grey[350]),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row shimmer
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(6, (_) => Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 12.0, bottom: 12.0),
                child: _shimmerBrandPill(),
              )),
            ),
          ),

          const SizedBox(height: 16),

          // Search bar shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const SizedBox(height: 16),
          //Teratas
          Row(
            children: [
              Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: 120, height: 12, color: Colors.grey[300])),
              const Spacer(),
              Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: 20, height: 12, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(4, (_) => _shimmerProductCard()),
            ),
          ),

          const SizedBox(height: 16),

          // Section 2 title + horizontal shimmer list (Mouse)
          Row(
            children: [
              Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: 80, height: 16, color: Colors.grey[300])),
              const Spacer(),
              Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: 20, height: 16, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(4, (_) => _shimmerProductCard()),
            ),
          ),

          const SizedBox(height: 16),

          // Section 3 title + horizontal shimmer list (Lainnya)
          Row(
            children: [
              Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: 80, height: 16, color: Colors.grey[300])),
              const Spacer(),
              Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(width: 20, height: 16, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(4, (_) => _shimmerProductCard()),
            ),
          ),

          const SizedBox(height: 24),

          // Optional bottom CTA shimmer (logout-like or button placeholder)
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }



  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ServicePage()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
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
            icon: Icon(Icons.build_circle_outlined), label: 'Service'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), label: 'Beli'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Beranda'),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/image/promo.png',
            width: 24,
            height: 24,
            color: Colors.white70,
          ),
          label: 'Promo',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
