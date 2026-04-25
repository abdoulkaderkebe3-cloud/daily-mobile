import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EnteteProfil extends StatefulWidget {
  final bool modeEdition;
  final ValueChanged<bool> onToggleEdition;

  const EnteteProfil({
    super.key,
    required this.modeEdition,
    required this.onToggleEdition,
  });

  @override
  EnteteProfilState createState() => EnteteProfilState();
}

class EnteteProfilState extends State<EnteteProfil> {
  final TextEditingController _pseudoCtrl = TextEditingController();
  bool _enTrainDeModifierPseudo = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _pseudoCtrl.text = provider.donneesUtilisateur?['username'] ?? "";
    _pseudoCtrl.addListener(() => setState(() {}));
  }

  Future<void> _gererMiseAJourPseudo() async {
    final provider = context.read<AppProvider>();
    final pseudo = provider.donneesUtilisateur?['username'];
    final nouveauPseudo = _pseudoCtrl.text.trim();

    if (nouveauPseudo.isEmpty || nouveauPseudo == pseudo) {
      setState(() => _enTrainDeModifierPseudo = false);
      return;
    }

    final id = provider.donneesUtilisateur?['id'];
    if (id == null) return;

    try {
      final res = await ApiService.mettreAJourUtilisateur(id.toString(), {'username': nouveauPseudo});
      provider.setDonneesUtilisateur({...provider.donneesUtilisateur!, ...res});
      setState(() => _enTrainDeModifierPseudo = false);
      provider.afficherNotification("Pseudo mis à jour !", type: "succes");
    } catch (err) {
      String msg = "Erreur lors de la mise à jour";
      if (err.toString().contains("409")) {
        msg = "Ce nom d'utilisateur est déjà utilisé.";
      }
      provider.afficherNotification(msg, type: "erreur");
    }
  }

  Future<void> _gererChangementPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    final provider = context.read<AppProvider>();
    final id = provider.donneesUtilisateur?['id'];
    if (id == null) return;

    try {
      final res = await ApiService.mettreAJourPhotoProfil(id.toString(), image.path);
      if (res['user'] != null) {
        provider.setDonneesUtilisateur({...provider.donneesUtilisateur!, ...res['user']});
      } else {
        // Fallback or full refresh
        provider.setDonneesUtilisateur({...provider.donneesUtilisateur!, 'photoProfil': res['photoProfil'] ?? res['user']?['photoProfil']});
      }
      provider.afficherNotification("Photo mise à jour !", type: "succes");
    } catch (err) {
      provider.afficherNotification("Erreur lors de l'envoi", type: "erreur");
    }
  }

  Future<void> _gererSupprimerPhoto() async {
    final provider = context.read<AppProvider>();
    final id = provider.donneesUtilisateur?['id'];
    if (id == null) return;

    try {
      await ApiService.supprimerPhotoProfil(id.toString());
      final u = Map<String, dynamic>.from(provider.donneesUtilisateur!);
      u['photoProfil'] = null;
      provider.setDonneesUtilisateur(u);
      provider.afficherNotification("Photo supprimée", type: "succes");
    } catch (_) {
      provider.afficherNotification("Erreur suppression", type: "erreur");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    context.select<AppProvider, String>((p) => p.langue);
    final user = context.select<AppProvider, Map<String, dynamic>?>((p) => p.donneesUtilisateur);
    final theme = Theme.of(context);
    
    final pseudo = user?['username'] ?? "Utilisateur";
    final points = user?['total_score'] ?? 0;
    final rang = user?['rang'] ?? "N/A";
    final avatarUrl = user?['photoProfil'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildControlBtn(
                onTap: () => widget.onToggleEdition(!widget.modeEdition),
                icon: widget.modeEdition ? PhosphorIcons.arrowLeft() : PhosphorIcons.slidersHorizontal(),
                theme: theme,
                active: widget.modeEdition,
              ),
            ],
          ),
          
          const SizedBox(height: 10),

          GestureDetector(
              onTap: () {
                if (widget.modeEdition) {
                  _gererChangementPhoto();
                } else if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
                  provider.setImageZoomee(avatarUrl);
                }
              },
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) 
                      ? CachedNetworkImageProvider(avatarUrl) 
                      : null,
                    backgroundColor: theme.brightness == Brightness.light ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
                    child: (avatarUrl == null || avatarUrl.isEmpty || !avatarUrl.startsWith('http')) 
                      ? Icon(PhosphorIcons.user(), size: 40, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3))
                      : null,
                  ),
                ),
                if (widget.modeEdition)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 2),
                      ),
                      child: Icon(
                        PhosphorIcons.camera(), 
                        color: theme.brightness == Brightness.light ? Colors.white : Colors.black, 
                        size: 16
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (widget.modeEdition && _enTrainDeModifierPseudo)
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pseudoCtrl,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      onSubmitted: (_) => _gererMiseAJourPseudo(),
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.brightness == Brightness.light ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        hintText: "Nouveau pseudo...",
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildControlBtn(
                    onTap: _gererMiseAJourPseudo, 
                    icon: PhosphorIcons.check(), 
                    theme: theme,
                    active: true,
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () {
                if (widget.modeEdition) setState(() => _enTrainDeModifierPseudo = true);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pseudo,
                    style: GoogleFonts.inter(
                      fontSize: 24, 
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.modeEdition)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(
                        PhosphorIcons.pencilSimple(),
                        size: 18,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
            ),
            
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1),
          ),
          
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem("POINTS", "$points", theme),
                ),
                VerticalDivider(width: 1, color: theme.dividerColor, indent: 5, endIndent: 5),
                Expanded(
                  child: _buildStatItem("RANG", "#$rang", theme, isRank: true),
                ),
              ],
            ),
          ),
          
          if (widget.modeEdition && (avatarUrl != null && avatarUrl.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton.icon(
                onPressed: _gererSupprimerPhoto,
                icon: Icon(PhosphorIcons.trash(), size: 16),
                label: Text(provider.t("btn_supprimer_photo").toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme, {bool isRank = false}) {
    Widget valueWidget;
    
    if (isRank) {
      final cleanValue = value.toString().replaceAll('#', '').toLowerCase().trim();
      if (cleanValue == "1") {
        valueWidget = Image.asset('assets/images/svg-1er.png', width: 32, height: 32);
      } else if (cleanValue == "2") {
        valueWidget = Image.asset('assets/images/svg-2eme.png', width: 32, height: 32);
      } else if (cleanValue == "3") {
        valueWidget = Image.asset('assets/images/svg-3eme.png', width: 32, height: 32);
      } else {
        valueWidget = Text(
          value, 
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
        );
      }
    } else {
      valueWidget = Text(
        value, 
        style: GoogleFonts.robotoMono(fontSize: 20, fontWeight: FontWeight.w700),
      );
    }

    return Column(
      children: [
        Text(
          label, 
          style: GoogleFonts.inter(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4), 
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          )
        ),
        const SizedBox(height: 4),
        SizedBox(height: 32, child: Center(child: valueWidget)),
      ],
    );
  }

  Widget _buildControlBtn({required VoidCallback onTap, required IconData icon, required ThemeData theme, bool active = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? theme.primaryColor.withOpacity(0.2) : theme.dividerColor),
        ),
        child: Icon(icon, size: 20, color: active ? theme.primaryColor : theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
      ),
    );
  }
}
