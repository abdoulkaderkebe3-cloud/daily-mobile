import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onTermine;

  const WelcomeScreen({super.key, required this.onTermine});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Transition vers l'app après 2.7 secondes (comme dans viso-studio)
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) widget.onTermine();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Center(
          child: SvgPicture.asset(
            isDark ? 'assets/images/logo-viso-logo.svg' : 'assets/images/logo-viso-noir.svg',
            width: 160,
            fit: BoxFit.contain,
          )
          .animate()
          // Phase d'entrée
          .fadeIn(duration: 500.ms, curve: Curves.easeIn)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 500.ms)
          
          // Effet Pulse (continue pendant la phase visible)
          .then(delay: 0.ms)
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 1000.ms,
            curve: Curves.easeInOut,
          )
          
          // Phase de sortie (commence à 2000ms)
          .animate() // Nouveau contrôleur pour la sortie
          .then(delay: 2000.ms)
          .fadeOut(duration: 700.ms, curve: Curves.easeOut)
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.1, 1.1),
            duration: 700.ms,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
  }
}
