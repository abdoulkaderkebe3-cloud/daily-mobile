import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final vueActive = context.select<AppProvider, String>((p) => p.vueActive);
    // On sélectionne la langue pour que la nav bar se reconstruise si la langue change
    context.select<AppProvider, String>((p) => p.langue);
    final theme = Theme.of(context);
    
    final boutons = [
      {'vue': 'accueil', 'icone': PhosphorIcons.pencilSimple(), 'cle': 'nav_defi'},
      {'vue': 'classement', 'icone': PhosphorIcons.trophy(), 'cle': 'nav_classement'},
      {'vue': 'profil', 'icone': PhosphorIcons.user(), 'cle': 'nav_profil'},
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: boutons.map((btn) {
              final isActif = vueActive == btn['vue'];
              final color = isActif ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withOpacity(0.4);

              return InkWell(
                onTap: () => provider.changerVue(btn['vue'] as String),
                child: SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(0, isActif ? -2 : 0, 0),
                        child: Icon(
                          btn['icone'] as IconData,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.t(btn['cle'] as String).toUpperCase(),
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActif ? 4 : 0,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
