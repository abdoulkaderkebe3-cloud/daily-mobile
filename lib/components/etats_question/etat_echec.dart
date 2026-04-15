import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EtatEchec extends StatelessWidget {
  final String reponseCorrecte;
  final String explication;

  const EtatEchec({
    super.key,
    required this.reponseCorrecte,
    required this.explication,
  });

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
            color: const Color(0xFFEF4444).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              PhosphorIcons.warningCircle(),
              color: const Color(0xFFEF4444),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          provider.t("titre_echec"),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "La réponse était :",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reponseCorrecte.isEmpty ? "..." : reponseCorrecte,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: const Color(0xFFEF4444),
          ),
        ),
        if (explication.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              explication,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          provider.t("msg_pas_loin"),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
