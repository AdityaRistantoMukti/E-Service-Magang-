import 'dart:async';
import 'package:e_service/Auth/login.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/birthday_notification_service.dart';
import 'package:e_service/Teknisi/teknisi_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:video_player/video_player.dart';
import 'Others/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize birthday notification service
  await BirthdayNotificationService.initialize();

  bool isLoggedIn = await SessionManager.isLoggedIn();
  final session = await SessionManager.getUserSession();
  final role = session['role'];

  //   // 🔹 Inisialisasi Midtrans SDK sesuai versi 1.1.0
  //   final midtrans = await MidtransSDK.init(
  //     config: MidtransConfig(
  //       clientKey: PaymentService.midtransClientKey,
  //       merchantBaseUrl: PaymentService.baseUrl,
  //       enableLog: true,
  //       colorTheme: ColorTheme(
  //         colorPrimary: Colors.blue,
  //         colorPrimaryDark: Colors.blueAccent,
  //         colorSecondary: Colors.white,
  //       ),
  //     ),
  //   );

  // // Set instance ke PaymentService
  // PaymentService.setInstance(midtrans);



  runApp(MyApp(isLoggedIn: isLoggedIn, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;
  const MyApp({super.key, required this.isLoggedIn, this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('id', 'ID'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SplashScreen(isLoggedIn: isLoggedIn, role: role),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String? role;
  const SplashScreen({super.key, required this.isLoggedIn, this.role});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/video/splash_screen.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.play();
        _controller.setLooping(false);
      });

    // Navigate after 5 seconds regardless of video duration
    Timer(const Duration(seconds: 5), _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    if (mounted) {
      BirthdayNotificationService.scheduleDailyBirthdayCheck();

      if (widget.isLoggedIn) {
        Widget nextPage;
        if (widget.role == 'karyawan') {
          nextPage = const TeknisiHomePage();
        } else {
          nextPage = const HomePage();
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => nextPage),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isVideoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Container(color: Colors.white), // Placeholder while video loads
    );
  }
}

class CircleRevealPainter extends CustomPainter {
  final double progress;
  CircleRevealPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    final maxRadius =
        (size.width > size.height ? size.width : size.height) * 1.2;
    final radius = maxRadius * progress;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleRevealPainter oldDelegate) =>
      oldDelegate.progress != progress;
}