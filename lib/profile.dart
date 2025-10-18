import 'package:e_service/scan_qr_admin.dart';
import 'package:e_service/services/api_service.dart';
import 'package:e_service/session_manager.dart';
import 'package:e_service/show_qr_addcoin.dart';
import 'package:e_service/show_qr_detail.dart';
import 'package:e_service/user_point_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'service.dart';
import 'Shop.dart';
import 'home.dart';
import 'sell.dart';
import 'edit_profile.dart';
import 'scan_qr.dart';
import 'edit_name.dart';
import 'edit_birthday.dart';
import 'edit_nmtlpn.dart';
import 'login.dart';

// ==== LOADING WRAPPER ====
class LoadingWrapper extends StatelessWidget {
  final bool isLoading;
  final Widget shimmer;
  final Widget child;

  const LoadingWrapper({
    super.key,
    required this.isLoading,
    required this.shimmer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading ? shimmer : child;
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int currentIndex = 4; // Tab aktif: Profile
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = userData?['cos_nama'] ?? '-';
    final id = userData?['id_costomer'] ?? '-';
    final nohp = userData?['cos_hp'] ?? '-';
    final tglLahir = userData?['cos_tgl_lahir'] ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
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
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROFILE CARD
            LoadingWrapper(
              isLoading: isLoading,
              shimmer: _buildShimmerProfileCard(),
              child: _buildProfileCard(nama, id),
            ),
            const SizedBox(height: 24),

            // INFO TILES
            LoadingWrapper(
              isLoading: isLoading,
              shimmer: Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildShimmerInfoTile(),
                  ),
                ),
              ),
              child: Column(
                children: [
                  _infoTile(Icons.person, 'Nama', nama),
                  const SizedBox(height: 12),
                  _infoTile(Icons.calendar_today, 'Tanggal Lahir', tglLahir),
                  const SizedBox(height: 12),
                  _infoTile(Icons.phone, 'Nomor HP', nohp),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR BOXES
            LoadingWrapper(
              isLoading: isLoading,
              shimmer: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  2,
                  (index) => _buildShimmerQRBox(),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _qrBox(Icons.qr_code, 'Tunjukan QR', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ShowQrToAddCoins()),
                    );
                  }),
                  _qrBox(Icons.qr_code_scanner, 'Scan QR', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanQrPage()),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LOGOUT BUTTON
            LoadingWrapper(
              isLoading: isLoading,
              shimmer: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ServicePage()));
          } else if (index == 1) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MarketplacePage()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const HomePage()));
          } else if (index == 3) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CekHargaPage()));
          } else if (index == 4) {
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'Service',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Beli',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell_outlined),
            label: 'Jual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ==== SHIMMER WIDGETS ====
  Widget _buildShimmerProfileCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            CircleAvatar(radius: 35, backgroundColor: Colors.grey[400]),
            const SizedBox(height: 10),
            Container(width: 120, height: 16, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Container(width: 60, height: 14, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 30, height: 14, color: Colors.grey[400]),
                const SizedBox(width: 10),
                Container(width: 20, height: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Container(width: 14, height: 14, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerInfoTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildShimmerQRBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ==== NORMAL WIDGETS ====
  Widget _buildProfileCard(String nama, String id) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1976D2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.black12,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.black,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF1976D2),
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(id, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Poin', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              ValueListenableBuilder<int>(
                valueListenable: UserPointData.userPoints,
                builder: (context, points, _) {
                  return Text('$points', style: const TextStyle(fontWeight: FontWeight.bold));
                },
              ),
              const SizedBox(width: 4),
              Image.asset('assets/image/coin.png', width: 16, height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qrBox(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 60, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1976D2)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
