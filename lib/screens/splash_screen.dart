import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _phase = 1; // 1 = The Daily Muse, 2 = Viso Studio

  @override
  void initState() {
    super.initState();
    _playSequence();
  }

  Future<void> _playSequence() async {
    // Phase 1 : The Daily Muse (~3s total)
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    setState(() => _phase = 2);

    // Phase 2 : Viso Studio (~3s total)
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _phase == 1
            ? _AnimatedSplashLogo(
                key: const ValueKey('phase1'),
                logoWidget: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(PhosphorIcons.asterisk(), color: Colors.black, size: 28),
                  ),
                ),
                isLogoRaw: false,
                title: 'The Daily Muse',
                subtitle: 'BY VISO STUDIO',
              )
            : _AnimatedSplashLogo(
                key: const ValueKey('phase2'),
                logoWidget: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/images/logo-viso-noir.svg',
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                isLogoRaw: false,
                title: 'Viso Studio',
                subtitle: null,
              ),
      ),
    );
  }
}

class _AnimatedSplashLogo extends StatefulWidget {
  /// Le widget à afficher comme logo (SVG brut ou Container avec icône)
  final Widget logoWidget;

  /// Si true, le logo est affiché directement sans wrapper Container
  final bool isLogoRaw;

  final String title;
  final String? subtitle;

  const _AnimatedSplashLogo({
    super.key,
    required this.logoWidget,
    required this.isLogoRaw,
    required this.title,
    this.subtitle,
  });

  @override
  State<_AnimatedSplashLogo> createState() => _AnimatedSplashLogoState();
}

class _AnimatedSplashLogoState extends State<_AnimatedSplashLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Phase A: scale & fade in logo
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Phase B: slide logo up
  late Animation<Offset> _logoOffset;

  // Phase C: text slide & fade in
  late Animation<double> _textOpacity;
  late Animation<Offset> _textOffset;

  // Phase D: global fade out
  late Animation<double> _globalOpacity;

  @override
  void initState() {
    super.initState();
    // Total duration = 2800ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // A: 0ms → 500ms  — Scale & FadeIn logo
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.18, curve: Curves.easeIn),
      ),
    );

    // B: 500ms → 1000ms — Slide logo up
    _logoOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -0.38)).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.36, curve: Curves.easeInOut),
      ),
    );

    // C: 850ms → 1350ms — Text fade in + slide up
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.50, curve: Curves.easeOut),
      ),
    );
    _textOffset = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.50, curve: Curves.easeOut),
      ),
    );

    // D: 2300ms → 2800ms — Global fade out
    _globalOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.82, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _globalOpacity.value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo: scale → translate
                SlideTransition(
                  position: _logoOffset,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: widget.logoWidget,
                    ),
                  ),
                ),

                // Text: slide up + fade in
                SlideTransition(
                  position: _textOffset,
                  child: Opacity(
                    opacity: _textOpacity.value,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
