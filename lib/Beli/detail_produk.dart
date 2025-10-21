
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/checkout.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class DetailProdukPage extends StatefulWidget {
  final Map<String, dynamic> produk;

  DetailProdukPage({super.key, required this.produk});

  

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}


class _DetailProdukPageState extends State<DetailProdukPage> {
  int currentIndex = 1;
  String? selectedShipping;

  final formatRupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/image/logo.png', height: 30),
            Image.asset('assets/image/asus_logo.png', height: 20),
            const Spacer(),
            const Icon(Icons.notifications_none, color: Colors.white),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== GAMBAR PRODUK ====
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF90CAF9),
                borderRadius: BorderRadius.circular(16),
                image: (widget.produk['gambar'] != null &&
                        widget.produk['gambar'].toString().isNotEmpty)
                    ? DecorationImage(
                        image: widget.produk['gambar'].toString().startsWith('assets/')
                            ? AssetImage(widget.produk['gambar'].toString())
                            : NetworkImage(widget.produk['gambar'].toString())
                                as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (widget.produk['gambar'] == null ||
                      widget.produk['gambar'].toString().isEmpty)
                  ? const Center(
                      child: Icon(Icons.image_outlined,
                          color: Colors.white70, size: 64),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // ==== NAMA PRODUK ====
            Text(
              widget.produk['nama_produk'] ?? 'Produk Tidak Dikenal',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ==== BRAND PRODUK ====
            if (widget.produk['brand'] != null)
              Text(
                widget.produk['brand'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

            const SizedBox(height: 10),

            // ==== DESKRIPSI ====
            Text(
              widget.produk['deskripsi'] ??
                  'Deskripsi produk belum tersedia untuk item ini.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 10),

            // ==== HARGA ====
            
           Text(
              formatRupiah.format(
                (widget.produk['harga'] is int)
                    ? widget.produk['harga']
                    : (widget.produk['harga'] is double)
                        ? widget.produk['harga']
                        : double.tryParse(widget.produk['harga'].toString()) ?? 0,
              ),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B4D3B),
            ),
          ),
            const SizedBox(height: 8),

            // ==== TOMBOL BELI ====
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckoutPage(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              label: Text(
                'Beli',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
            ),

            const SizedBox(height: 16),

            // ==== LAINNYA ====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lainnya',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 8),
            _buildProductList(),

            const SizedBox(height: 16),

            // ==== SERUPA ====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Serupa',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 8),
            _buildProductList(),
          ],
        ),
      ),


      // ===== Bottom Navigation Bar =====
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
            setState(() {
              currentIndex = index;
            });
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
                ? Image.asset(
                    'assets/image/promo.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  )
                : Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      'assets/image/promo.png',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
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

  Widget _buildProductList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBDEFB),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASUS Mouse',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rp 150.000',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red,
                        ),
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

  void _showShippingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Ekspedisi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _shippingItem(Icons.local_shipping, "J&T"),
              _shippingItem(Icons.delivery_dining, "SiCepat"),
              _shippingItem(Icons.local_shipping_outlined, "JNE"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _shippingItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        setState(() {
          selectedShipping = label;
        });
        Navigator.pop(context);
      },
    );
  }

  IconData _getShippingIcon(String shipping) {
    switch (shipping) {
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
}
