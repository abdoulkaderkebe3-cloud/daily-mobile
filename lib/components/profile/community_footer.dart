import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityFooter extends StatelessWidget {
  const CommunityFooter({super.key});

  Future<void> _lancerUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback or ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
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
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _lancerUrl("https://whatsapp.com/channel/0029Vb6avN0InlqWut6HV70k"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "REJOINDRE LA COMMUNAUTÉ", 
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          
          InkWell(
            onTap: () {
              final message = Uri.encodeComponent("Rejoins-moi sur Daily Muse pour relever les défis quotidiens !");
              _lancerUrl("https://wa.me/?text=$message");
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.shareNetwork(), size: 20, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    "PARRAINER UN AMI",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
