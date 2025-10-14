import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

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
                    margin: const EdgeInsets.only(top: 5),
                    child: Text(
                      'Service | Penjualan | Pengadaan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.width * 0.035,
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
                              onTap: () => setState(() => isLogin = false),
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
                    if (!isLogin) ...[
                      _buildTextField('Nama Lengkap', false),
                      SizedBox(height: screenSize.height * 0.02),
                    ],
                    _buildTextField('Alamat E-Mail', false, icon: Icons.email),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildTextField('Kata sandi', true),
                    if (!isLogin) ...[
                      SizedBox(height: screenSize.height * 0.02),
                      _buildTextField('Konfirmasi Kata sandi', true),
                    ],

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
    bool isConfirm = hint.contains('Ulang');
    return TextField(
      obscureText: isPassword &&
          ((isConfirm && !showConfirmPassword) || (!isConfirm && !showPassword)),
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
                  (isConfirm ? showConfirmPassword : showPassword)
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: const Color(0xFF0D47A1),
                  size: screenSize.width * 0.05,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirm) {
                      showConfirmPassword = !showConfirmPassword;
                    } else {
                      showPassword = !showPassword;
                    }
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
