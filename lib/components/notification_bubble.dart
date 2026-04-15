import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NotificationBubble extends StatelessWidget {
  final String message;
  final String type; // 'succes' or 'erreur'

  const NotificationBubble({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == 'succes';
    final accentColor = isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isSuccess ? PhosphorIcons.checkCircle() : PhosphorIcons.warningCircle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodyMedium?.color, 
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .slideY(begin: 0.5, end: 0.0, curve: Curves.easeOutCubic);
  }
}
