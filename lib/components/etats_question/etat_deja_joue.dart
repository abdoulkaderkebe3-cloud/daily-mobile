import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EtatDejaJoue extends StatelessWidget {
  final String message;

  const EtatDejaJoue({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Note: We don't necessarily need to select AppProvider here if we don't use it, 
    // but leaving it empty if no translations are needed or using select if needed.
    // Actually, looking at the code, provider is not even used!
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.clock(),
              color: theme.primaryColor,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Déjà joué !",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
