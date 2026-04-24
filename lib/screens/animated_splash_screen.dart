import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _textFadeAnim = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/dmjklogo.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Brand name + tagline
              FadeTransition(
                opacity: _textFadeAnim,
                child: SlideTransition(
                  position: _textSlideAnim,
                  child: Column(
                    children: [
                      const Text(
                        'DMJK Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Shop smarter. Live better.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Loading dots
              FadeTransition(
                opacity: _textFadeAnim,
                child: SizedBox(
                  width: 40,
                  height: 4,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
