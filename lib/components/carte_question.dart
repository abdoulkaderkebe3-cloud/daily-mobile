import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'etats_question/etat_actif.dart';
import 'etats_question/etat_succes.dart';
import 'etats_question/etat_echec.dart';

class CarteQuestion extends StatelessWidget {
  final String etat; // "actif" | "succes" | "echec"
  final String question;
  final String categorie;
  final String reponseCorrecte;
  final String explication;
  final Future<void> Function({required String reponse}) onSoumettre;
  final VoidCallback onPartager;

  const CarteQuestion({
    super.key,
    required this.etat,
    required this.question,
    required this.categorie,
    required this.reponseCorrecte,
    required this.explication,
    required this.onSoumettre,
    required this.onPartager,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bouton Partage (Flottant en haut à droite)
          Positioned(
            top: -10,
            right: -10,
            child: _buildFloatingButton(
              onPartager,
              PhosphorIcons.shareNetwork(),
              theme,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildContent(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildFloatingButton(VoidCallback onTap, IconData icon, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
          shape: BoxShape.circle,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(icon, size: 20, color: theme.textTheme.bodyMedium?.color),
      ),
    );
  }

  Widget _buildContent() {
    switch (etat) {
      case "succes":
        return const EtatSucces();
      case "echec":
        return EtatEchec(
          reponseCorrecte: reponseCorrecte,
          explication: explication,
        );
      case "actif":
      default:
        return EtatActif(
          question: question,
          categorie: categorie,
          onSoumettre: onSoumettre,
        );
    }
  }
}
