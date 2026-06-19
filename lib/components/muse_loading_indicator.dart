import 'package:flutter/material.dart';

class MuseLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const MuseLoadingIndicator({super.key, this.size = 40.0, this.color});

  @override
  State<MuseLoadingIndicator> createState() => _MuseLoadingIndicatorState();
}

class _MuseLoadingIndicatorState extends State<MuseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Vitesse de rotation (identique au pull-to-refresh)
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.color ?? theme.primaryColor;

    return RotationTransition(
      turns: _rotationController,
      child: Image.asset(
        'assets/images/actualisation.png',
        width: widget.size,
        height: widget.size,
        color: accentColor,
      ),
    );
  }
}
