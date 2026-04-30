import 'package:flutter/material.dart';
import 'package:project_kim/features/home/presentation/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _step = 0;
  double _opacity = 1.0;

  // Ajustes de duración
  final Duration _logoVisibleDuration = const Duration(milliseconds: 1800);
  final Duration _fadeDuration = const Duration(milliseconds: 650);

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    // ==========================
    // STEP 1: DRAVEX
    // ==========================
    setState(() {
      _step = 0;
      _opacity = 1.0;
    });

    await Future.delayed(_logoVisibleDuration);

    // Fade out
    setState(() => _opacity = 0.0);
    await Future.delayed(_fadeDuration);

    // ==========================
    // STEP 2: EXPERIENCIAS 360
    // ==========================
    setState(() {
      _step = 1;
      _opacity = 1.0;
    });

    await Future.delayed(_logoVisibleDuration);

    // Fade out
    setState(() => _opacity = 0.0);
    await Future.delayed(_fadeDuration);

    // ==========================
    // STEP 3: ENTER APP
    // ==========================
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String logoPath;

    if (_step == 0) {
      logoPath = "assets/logos/logo_dravex.png";
    } else {
      logoPath = "assets/logos/logo_experiencias360.png";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: _fadeDuration,
          opacity: _opacity,
          curve: Curves.easeInOut,
          child: AnimatedScale(
            duration: _fadeDuration,
            curve: Curves.easeInOut,
            scale: _opacity == 1.0 ? 1.0 : 0.92,
            child: Image.asset(
              logoPath,
              width: 260,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}