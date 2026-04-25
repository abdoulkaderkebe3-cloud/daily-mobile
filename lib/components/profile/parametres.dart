import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Parametres extends StatelessWidget {
  final Future<void> Function() onDeconnexion;

  const Parametres({super.key, required this.onDeconnexion});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    context.select<AppProvider, String>((p) => p.theme);
    context.select<AppProvider, String>((p) => p.langue);
    final theme = Theme.of(context);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            provider.t("titre_parametres"),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, 
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildParamRow(
            label: "NOTIFICATIONS",
            buttonLabel: "ACTIVER",
            icon: PhosphorIcons.bell(),
            onPressed: () {
              provider.afficherNotification("Notifications activées !", type: "succes");
            },
            theme: theme,
          ),
          
          _buildDivider(theme),
          
          _buildParamRow(
            label: provider.t("lbl_theme").toUpperCase(),
            buttonLabel: provider.theme == "dark" ? "SOMBRE" : "CLAIR",
            icon: provider.theme == "dark" ? PhosphorIcons.moon() : PhosphorIcons.sun(),
            onPressed: provider.basculerTheme,
            theme: theme,
          ),
          
          _buildDivider(theme),
          
          _buildParamRow(
            label: provider.t("lbl_langue").toUpperCase(),
            buttonLabel: provider.langue.toUpperCase(),
            icon: PhosphorIcons.translate(),
            onPressed: provider.basculerLangue,
            theme: theme,
          ),
          
          _buildDivider(theme),
          
          _buildParamRow(
            label: "ZONE DE DANGER",
            labelColor: const Color(0xFFEF4444),
            buttonLabel: "DÉCONNEXION",
            buttonColor: const Color(0xFFEF4444),
            icon: PhosphorIcons.signOut(),
            onPressed: onDeconnexion,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
    );
  }

  Widget _buildParamRow({
    required String label,
    required String buttonLabel,
    IconData? icon,
    required VoidCallback onPressed,
    required ThemeData theme,
    Color? labelColor,
    Color? buttonColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: labelColor ?? theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: (buttonColor ?? theme.dividerColor).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (buttonColor ?? theme.dividerColor).withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: buttonColor ?? theme.textTheme.bodyMedium?.color),
                  if (buttonLabel.isNotEmpty) const SizedBox(width: 8),
                ],
                if (buttonLabel.isNotEmpty)
                  Text(
                    buttonLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10, 
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: buttonColor ?? theme.textTheme.bodyMedium?.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
