import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Gunakan alias agar tidak bentrok dengan HomePage di Shop.dart
import 'service.dart';
import 'shop.dart';
import 'promo.dart';
import 'profile.dart';
import 'notifikasi.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 2; // posisi default: Home

  @override
  Widget build(BuildContext context) {
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
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Member Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
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
                        'Udin',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Id 202234001',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Banner Slider Dummy (bisa ganti pake carousel slider)
            SizedBox(
              height: 150,
              child: PageView.builder(
                itemCount: 5,
                controller: PageController(viewportFraction: 0.9),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue[(index + 1) * 100],
                    ),
                  );
                },
              ),
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {},
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
                              color: Colors.grey.shade300,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ASUS ROG STRIX G15',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp 15.999.000',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.8 | 500+ terjual',
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
            icon:
                currentIndex == 3
                    ? Image.asset(
                      'assets/image/promo.png',
                      width: 24,
                      height: 24,
                    )
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
      ),
    );
  }
}
