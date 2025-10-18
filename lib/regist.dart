import 'package:e_service/services/api_service.dart';
import 'package:e_service/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'auth_service.dart';
import 'Home.dart';
import 'auth_service.dart';
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  final AuthService _authService = AuthService();

  final nameController = TextEditingController();                        
  final nohpController = TextEditingController();                        
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final tglLahirController = TextEditingController();


  // ⬇️ Tambahkan ini
  String tglLahirAsli = "";

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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              ),
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
                       _buildTextField('Nomor HP', false, icon: Icons.phone), 
                        SizedBox(height: screenSize.height * 0.02),
                    ],                    
                   _buildTextField('Tanggal Lahir', false, icon: Icons.calendar_today),
                    SizedBox(height: screenSize.height * 0.02),                                          
                    _buildTextField('Kata Sandi', true),
                    if (!isLogin) ...[
                      SizedBox(height: screenSize.height * 0.02),
                      _buildTextField('Konfirmasi Kata Sandi', true),
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
                     onPressed: () async {
                        
                        if (nameController.text.isEmpty || passwordController.text.isEmpty || nohpController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Harap isi semua kolom terlebih dahulu')),
                          );
                          return;
                        }

                        if (passwordController.text != confirmController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kata sandi dan konfirmasi tidak sama')),
                          );
                          return;
                        }

                        try {
                          final result = await ApiService.registerUser(
                            nameController.text.trim(),
                            passwordController.text.trim(),
                            nohpController.text.trim(),
                            tglLahirAsli.trim(),
                          );

                          if (result['success'] == true) {
                            await SessionManager.saveUserSession(
                              result['costomer']['id_costomer'].toString(),
                              result['costomer']['cos_nama'],
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Registrasi berhasil!')),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          } else {
                            String message;
                            switch (result['code']) {
                              case 4091:
                                message = 'Nomor HP sudah terdaftar. Gunakan nomor lain.';
                                break;
                              case 4092:
                                message = 'Nama dan password sudah digunakan.';
                                break;
                              case 422:
                                message = 'Nomor HP harus berupa angka 10-13 digit.';
                                break;
                              default:
                                message = 'Terjadi kesalahan. Coba lagi.';
                            }

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal terhubung ke server.')),
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

  // Deteksi apakah field ini adalah "Konfirmasi Kata Sandi"
  bool isConfirm = hint.toLowerCase().contains('konfirmasi');

  // Pilih controller berdasarkan hint
  TextEditingController? controller;
  if (hint == 'Nama Lengkap') {
    controller = nameController;
  } else if (hint == 'Nomor HP') {
      controller = nohpController;  
  }else if (hint == 'Kata Sandi') {
    controller = passwordController;
  } else if (hint == 'Konfirmasi Kata Sandi') {
    controller = confirmController;
  } else if (hint == 'Tanggal Lahir') {
  controller = tglLahirController;
}
  // Kalau ini field tanggal lahir, buat bisa klik & munculkan DatePicker
  bool isDateField = hint == 'Tanggal Lahir';

  return TextField(
    controller: controller,
    // Tanggal Lahir
    readOnly: isDateField,
    onTap: isDateField
        ? () async {
            FocusScope.of(context).requestFocus(FocusNode()); // Tutup keyboard
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              locale: const Locale('id', 'ID'),
            );
            if (pickedDate != null) {
            controller?.text = DateFormat('dd-MM-yyyy').format(pickedDate); // tampil di UI
            tglLahirAsli = DateFormat('yyyy-MM-dd').format(pickedDate); // dikirim ke backend
          }
          }
        : null,
    // No HP
    keyboardType: hint == 'Nomor HP' ? TextInputType.phone : TextInputType.text,
    // Passowrd
    obscureText: isPassword &&
        ((isConfirm && !showConfirmPassword) ||
         (!isConfirm && !showPassword)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: screenSize.width * 0.035,
        color: Colors.black54,
      ),
      filled: true,
      fillColor: const Color(0xFF1976D2).withValues(alpha: 0.15),

      // Icon untuk toggle visibility password
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
              ? Icon(
                  icon,
                  color: const Color(0xFF0D47A1),
                  size: screenSize.width * 0.05,
                )
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
