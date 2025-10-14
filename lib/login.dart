import 'package:flutter/material.dart';
import 'regist.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final padding = screenSize.width * 0.06; // 6% of screen width

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ====================== HEADER ======================
            Stack(
              children: [
                Container(
                  height: isLandscape ? screenSize.height * 0.4 : screenSize.height * 0.3,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E52B4),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: CustomPaint(painter: _BubblePainter()),
                ),

                // Logo
                Positioned(
                  top: isLandscape ? screenSize.height * 0.1 : screenSize.height * 0.08,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/image/logo.png',
                      width: isLandscape ? screenSize.width * 0.2 : screenSize.width * 0.45,
                      height: isLandscape ? screenSize.height * 0.15 : screenSize.height * 0.12,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenSize.height * 0.03),

            // ====================== FORM LOGIN ======================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Masuk/Daftar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EEFF),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.015),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E52B4),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'Masuk',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
                              padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.015),
                              child: Center(
                                child: Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: const Color(0xFF4A8DFF),
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenSize.width * 0.04,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.045),

                  Text(
                    'Alamat E-Mail',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: screenSize.width * 0.04,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Masukan E-Mail',
                      filled: true,
                      fillColor: const Color(0xFF1E52B4),
                      hintStyle: const TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.02,
                        horizontal: screenSize.width * 0.05,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),

                  SizedBox(height: screenSize.height * 0.03),

                  Text(
                    'Kata sandi',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: screenSize.width * 0.04,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  TextField(
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Masukan Kata Sandi',
                      filled: true,
                      fillColor: const Color(0xFF1E52B4),
                      hintStyle: const TextStyle(color: Colors.white70),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.02,
                        horizontal: screenSize.width * 0.05,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Lupa Kata Sandi',
                        style: TextStyle(
                          color: const Color(0xFF4A8DFF),
                          fontSize: screenSize.width * 0.035,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.015),

                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E52B4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      ),
                      child: Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.024),

                  // Tombol Google
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/image/google.png',
                        width: screenSize.width * 0.05,
                      ),
                      label: Text(
                        'Masuk menggunakan Akun Google',
                        style: TextStyle(
                          color: const Color(0xFF1E52B4),
                          fontWeight: FontWeight.w600,
                          fontSize: screenSize.width * 0.035,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E52B4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenSize.height * 0.05), // Bottom padding
          ],
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
