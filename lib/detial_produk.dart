import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Contoh halaman lain (dummy)
class ServicePage extends StatelessWidget {
  const ServicePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Service Page')));
}

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Marketplace Page')));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Home Page')));
}

class TukarPoinPage extends StatelessWidget {
  const TukarPoinPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Tukar Poin Page')));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Profile Page')));
}

class DetailProdukPage extends StatefulWidget {
  const DetailProdukPage({super.key});

  @override
  State<DetailProdukPage> createState() => _DetailProdukPageState();
}

class _DetailProdukPageState extends State<DetailProdukPage> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/image/asus_logo.png', height: 30),
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
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF90CAF9),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'deskripsi produk kjahhehwek nkfnekwhfkelvjewl neklvlj vlewjv jvejve jvjypevj v lkvjrjvevo',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              'Rp 2.000.000',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text('Beli', style: GoogleFonts.poppins(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Bagian Lainnya =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lainnya', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_forward, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 8),
            _buildProductList(),

            const SizedBox(height: 16),

            // ===== Bagian Serupa =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Serupa', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServicePage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MarketplacePage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
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
                : Opacity(
                    opacity: 0.6,
                    child: Image.asset('assets/image/promo.png', width: 24, height: 24),
                  ),
            label: 'Promo',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
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
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBDEFB),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASUS Mouse', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Rp 150.000', style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
