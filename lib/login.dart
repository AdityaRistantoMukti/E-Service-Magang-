import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'regist.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final padding = screenSize.width * 0.06; // 6% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: SafeArea(
        child: Column(
          children: [
            // Header logo + title
            SizedBox(height: screenSize.height * 0.05),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/image/logo.png',
                    width: isLandscape ? screenSize.width * 0.2 : screenSize.width * 0.45,
                    height: isLandscape ? screenSize.height * 0.15 : screenSize.height * 0.12,
                  ),
                  Container(
                    width: isLandscape ? screenSize.width * 0.2 : screenSize.width * 0.45,
                    margin: const EdgeInsets.only(top: 0.4),
                    child: Text(
                      'Service | Penjualan | Pengadaan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.width * 0.02,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenSize.height * 0.04),

            // White container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: screenSize.height * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Toggle buttons
                    Container(
                      height: screenSize.height * 0.06,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isLogin = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLogin
                                      ? const Color(0xFF1976D2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Masuk',
                                  style: GoogleFonts.poppins(
                                    color: isLogin ? Colors.white : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenSize.width * 0.04,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AuthPage()),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !isLogin
                                      ? const Color(0xFF1976D2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Daftar',
                                  style: GoogleFonts.poppins(
                                    color: !isLogin ? Colors.white : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenSize.width * 0.04,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form fields
                    _buildTextField('Alamat E-Mail', false, icon: Icons.email),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildTextField('Kata sandi', true),

                    if (isLogin)
                      Padding(
                        padding: EdgeInsets.only(top: screenSize.height * 0.01),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Lupa Kata Sandi',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1976D2),
                              fontSize: screenSize.width * 0.035,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: screenSize.height * 0.03),

                    // Tombol utama
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLogin ? Colors.white : const Color(0xFF1976D2),
                        foregroundColor:
                            isLogin ? const Color(0xFF1976D2) : Colors.white,
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      ),
                      onPressed: () {},
                      child: Text(
                        isLogin ? 'Masuk' : 'Daftar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: screenSize.width * 0.04,
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),

                    // Tombol Google
                    OutlinedButton.icon(
                      icon: Image.asset(
                        'assets/image/google.png',
                        width: screenSize.width * 0.06,
                        height: screenSize.width * 0.06,
                      ),
                      label: Text(
                        'Masuk menggunakan Akun Google',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                          fontSize: screenSize.width * 0.035,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      ),
                      onPressed: () {},
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, bool isPassword, {IconData? icon}) {
    final screenSize = MediaQuery.of(context).size;
    return TextField(
      obscureText: isPassword && !showPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: screenSize.width * 0.035,
          color: Colors.black54,
        ),
        filled: true,
        fillColor: const Color(0xFF1976D2).withValues(alpha: 0.15),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF0D47A1),
                  size: screenSize.width * 0.05,
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              )
            : (icon != null
                ? Icon(icon, color: const Color(0xFF0D47A1), size: screenSize.width * 0.05)
                : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.02,
          horizontal: screenSize.width * 0.04,
        ),
      ),
    );
  }
}

// ====================== GELEMBUNG DI LATAR BELAKANG ======================
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF3C6FD6).withValues(alpha: 0.25);

    final bubbles = [
      const Offset(50, 100),
      const Offset(200, 50),
      const Offset(300, 150),
      const Offset(100, 200),
      const Offset(250, 220),
    ];

    for (var bubble in bubbles) {
      canvas.drawCircle(bubble, 25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
