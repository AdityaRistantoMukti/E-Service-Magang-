import 'package:flutter/material.dart';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Animasi lingkaran membesar
    _circleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
    );

    // Animasi logo muncul setelah lingkaran menutupi layar
    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            }
          });
        }
      });
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final circleValue = _circleAnimation.value;
          final logoVisible = _logoAnimation.value > 0.01;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.white),

              CustomPaint(
                painter: CircleRevealPainter(circleValue),
                child: Container(),
              ),

              if (logoVisible)
                Center(
                  child: Opacity(
                    opacity: _logoAnimation.value,
                    child: Transform.scale(
                      scale: _logoAnimation.value,
                      child: Image.asset(
                        'assets/image/logo.png',
                        width: isLandscape ? screenSize.width * 0.15 : screenSize.width * 0.4,
                        height: isLandscape ? screenSize.height * 0.2 : screenSize.height * 0.15,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class CircleRevealPainter extends CustomPainter {
  final double progress;
  CircleRevealPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E52B4);

    
    final maxRadius = (size.width > size.height ? size.width : size.height) * 1.2;
    final radius = maxRadius * progress;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleRevealPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
