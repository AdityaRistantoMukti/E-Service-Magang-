import 'package:e_service/Auth/login.dart';
import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Others/session_manager.dart';
import 'package:e_service/Others/user_point_data.dart';
import 'package:e_service/Profile/edit_birthday.dart';
import 'package:e_service/Profile/edit_name.dart';
import 'package:e_service/Profile/edit_nmtlpn.dart';
import 'package:e_service/Profile/edit_profile.dart';
import 'package:e_service/Profile/scan_qr.dart';
import 'package:e_service/Profile/show_qr_addcoin.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

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
  int currentIndex = 4;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      final id = userData?['id_costomer'] != null ? 'Id ${userData!['id_costomer']}' : '-';      
      final nohp = userData?['cos_hp'] ?? '-';
      final tglLahir = userData?['cos_tgl_lahir'] ?? '-';

      return Scaffold(
        backgroundColor: Colors.white,
        body: LoadingWrapper(
          isLoading: isLoading,
          // 🌟 Shimmer Layout — identik dengan layout normal
          shimmer: Stack(
            children: [
              // HEADER shimmer
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              // PROFILE CARD shimmer
              Positioned(
                top: 120,
                left: 16,
                right: 16,
                child: _buildShimmerProfileCard(),
              ),

              // BODY shimmer
              Padding(
                padding: const EdgeInsets.only(top: 300),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildShimmerBody(),
                ),
              ),
            ],
          ),

          // 🌟 Normal Layout setelah data tampil
          child: Stack(
            children: [
              // ==== HEADER ====
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Image.asset('assets/image/logo.png', width: 95, height: 30),
                      const Spacer(),
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
                ),
              ),

              // ==== PROFILE CARD ====
              Positioned(
                top: 120,
                left: 16,
                right: 16,
                child: _buildProfileCard(context, nama, id),
              ),

              // ==== BODY ====
              Padding(
                padding: const EdgeInsets.only(top: 300),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoTile(Icons.person, 'Nama', nama, onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const EditNamaPage()));
                      }),
                      const SizedBox(height: 12),
                      _infoTile(Icons.calendar_month, 'Tanggal Lahir', tglLahir, onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const EditBirthdayPage()));
                      }),
                      const SizedBox(height: 12),
                      _infoTile(Icons.phone, 'Nomor Telpon', nohp, onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const EditNmtlpnPage()));
                      }),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _qrBox(
                            Icons.qr_code,
                            'Tunjukan QR',
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(builder: (context) => const ShowQrToAddCoins()));
                            },
                          ),
                          _qrBox(
                            Icons.qr_code_scanner,
                            'Scan QR',
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(builder: (context) => const ScanQrPage()));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _contactTile(Icons.phone, nohp, Icons.chat),
                      const SizedBox(height: 12),
                      _contactTile(Icons.email_outlined, userData?['cos_email'] ?? '-', Icons.chat),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ==== NAVIGATION BAR ====
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index != currentIndex) {
              if (index == 0) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const ServicePage()));
              } else if (index == 1) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const MarketplacePage()));
              } else if (index == 2) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const HomePage()));
              } else if (index == 3) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const TukarPoinPage()));
              } else if (index == 4) {
                setState(() {
                  currentIndex = index;
                });
              }
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
                icon: Icon(Icons.shopping_cart_outlined), label: 'Beli'),
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: currentIndex == 3
                  ? Image.asset('assets/image/promo.png', width: 24, height: 24)
                  : Opacity(
                      opacity: 0.6,
                      child: Image.asset('assets/image/promo.png', width: 24, height: 24)),
              label: 'Promo',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      );
    }


  // ==================== WIDGET SUPPORT ====================

  Widget _buildProfileCard(BuildContext context, String nama, String id) {
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
                child: Icon(Icons.person, size: 50, color: Colors.black),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfilePage()),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.edit,
                        color: Color(0xFF1976D2), size: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(nama,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(id, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Poin',style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              ValueListenableBuilder<int>(
                valueListenable: UserPointData.userPoints,
                builder: (context, points, _) {
                  return Text('$points',style: const TextStyle(fontWeight: FontWeight.bold));
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

  Widget _qrBox(IconData icon, String label,{VoidCallback? onTap}) {
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

  Widget _contactTile(IconData icon, String text, IconData actionIcon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(text, style: const TextStyle(fontSize: 14))),
          Icon(actionIcon, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // shimmer placeholders
 Widget _buildShimmerBody() {
  return Column(
    children: [
      const SizedBox(height: 24),
      _buildShimmerInfoTile(),
      const SizedBox(height: 12),
      _buildShimmerInfoTile(),
      const SizedBox(height: 12),
      _buildShimmerInfoTile(),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [_buildShimmerQRBox(), _buildShimmerQRBox()],
      ),
      const SizedBox(height: 24),
      _buildShimmerInfoTile(),
      const SizedBox(height: 12),
      _buildShimmerInfoTile(),
    ],
  );
}


  Widget _buildShimmerProfileCard() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Foto profil shimmer
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // Kolom nama dan email shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: 180,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(30),
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
}
