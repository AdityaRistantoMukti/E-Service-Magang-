import 'package:e_service/forget_password.dart';
import 'package:e_service/services/api_service.dart';
import 'package:e_service/session_manager.dart';
import 'package:e_service/user_point_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'regist.dart';
import 'auth_service.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool showPassword = false;
  final AuthService _authService = AuthService();

  TextEditingController _namaController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final padding = screenSize.width * 0.06; // 6% of screen width

    return Scaffold(
      backgroundColor: Colors.blue,
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
                                      ? Colors.blue
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
                                      ? Colors.blue
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
                    _buildTextField('Nama', false, icon: Icons.person),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildTextField('Kata sandi', true),                    
                      if (isLogin)
                      Padding(
                        padding: EdgeInsets.only(top: screenSize.height * 0.01),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgetPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Lupa Kata Sandi',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1976D2),
                                fontSize: screenSize.width * 0.035,
                                decoration: TextDecoration.underline,
                              ),                        
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: screenSize.height * 0.03),
                  
                    // Tombol utama
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLogin ? Colors.white : Colors.blue,
                        foregroundColor:
                            isLogin ? Colors.blue : Colors.white,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      ),
                      onPressed: () async {
                          String nama = _namaController.text.trim();
                          String password = _passwordController.text.trim();

                          if (nama.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama dan password wajib diisi')),
                            );
                            return;
                          }
                                            
                      try {
                          final result = await ApiService.login(nama, password);
                          
                          if (result['success']) {
                            final user = result['user'];
                            // Simpan session
                            await SessionManager.saveUserSession(
                              result['user']['id_costomer'].toString(),
                              result['user']['cos_nama'],
                            );
                            final poin = int.tryParse(user['cos_poin'].toString()) ?? 0;
                            UserPointData.setPoints(poin);
                            // Login berhasil
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          } else {
                            // Login gagal
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'])),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },              
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
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: screenSize.width * 0.035,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                      ),
                      onPressed: _signInWithGoogle,
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
    final controller = hint == 'Nama' ? _namaController : _passwordController;
    return TextField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: screenSize.width * 0.035,
          color: Colors.black54,
        ),
        filled: true,
        fillColor: Colors.blue.withValues(alpha: 0.15),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.blue,
                  size: screenSize.width * 0.05,
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              )
            : (icon != null
                ? Icon(icon, color: Colors.blue, size: screenSize.width * 0.05)
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

  Future<void> _signInWithGoogle() async {
    try {
      final account = await _authService.signInWithGoogle();
      if (account != null) {
        // Successfully signed in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${account.displayName}!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home screen or next screen
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      } else {
        // Sign in failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


