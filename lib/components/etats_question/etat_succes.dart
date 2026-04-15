import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EtatSucces extends StatelessWidget {
  const EtatSucces({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.checkCircle(),
              color: const Color(0xFF10B981),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          provider.t("titre_succes"),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          provider.t("msg_revenir"),
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
