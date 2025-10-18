import 'package:e_service/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart'; // pastikan arah import sesuai lokasi file kamu

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _verificationCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.06;

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenSize.height * 0.05),

            // Header logo dan judul
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/image/logo.png',
                    width: screenSize.width * 0.45,
                    height: screenSize.height * 0.12,
                  ),
                  Text(
                    'Lupa Kata Sandi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Text(
                    'Masukkan kode verifikasi yang telah dikirim',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: screenSize.width * 0.035,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: screenSize.height * 0.04),

            // Box putih utama
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: screenSize.height * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _verificationCodeController,
                        hint: 'Kode Verifikasi',
                        icon: Icons.verified_outlined,
                      ),
                      SizedBox(height: screenSize.height * 0.03),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                        ),
                        onPressed: () {
                          String code = _verificationCodeController.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kode verifikasi wajib diisi')),
                            );
                            return;
                          }

                          // Simulasi kode benar (nanti bisa integrasi dengan API)
                          if (code == "123456") {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kode verifikasi salah')),
                            );
                          }
                        },
                        child: Text(
                          'Verifikasi Kode',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: screenSize.width * 0.04,
                          ),
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.02),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Kembali ke Halaman Masuk',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1976D2),
                            fontSize: screenSize.width * 0.04,
                          ),
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    final screenSize = MediaQuery.of(context).size;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: screenSize.width * 0.035,
          color: Colors.black54,
        ),
        filled: true,
        fillColor: const Color(0xFF1976D2).withValues(alpha: 0.15),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF0D47A1))
            : null,
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