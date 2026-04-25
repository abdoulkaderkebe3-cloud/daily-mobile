import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  LeaderboardViewState createState() => LeaderboardViewState();
}

class LeaderboardViewState extends State<LeaderboardView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  static const int limite = 10;
  List<dynamic> _classement = [];
  bool _chargement = true;
  bool _erreur = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _chargerClassement();
  }

  Future<void> _chargerClassement() async {
    final provider = context.read<AppProvider>();
    
    // Afficher le cache immédiatement si disponible
    if (provider.cacheClassement != null && _page == 1) {
      setState(() {
        _classement = provider.cacheClassement!;
        _chargement = false;
        _erreur = false;
      });
      // On ne fait PAS de return ici pour rafraîchir en arrière-plan
    } else {
      setState(() {
        _chargement = true;
        _erreur = false;
      });
    }

    try {
      final rep = await ApiService.obtenirUtilisateurs(page: _page, limite: limite)
          .timeout(const Duration(seconds: 30));
      final liste = rep['users'] ?? rep['data'] ?? [];
      if (mounted) {
        setState(() {
          _classement = liste;
          if (_page == 1) provider.setCacheClassement(liste);
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted && _classement.isEmpty) {
        setState(() => _erreur = true);
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Widget _buildMedaille(int rang, ThemeData theme) {
    final cleanValue = rang.toString().toLowerCase().trim();
    if (cleanValue == "1") {
      return Image.asset('assets/images/svg-1er.png', width: 32, height: 32);
    } else if (cleanValue == "2") {
      return Image.asset('assets/images/svg-2eme.png', width: 32, height: 32);
    } else if (cleanValue == "3") {
      return Image.asset('assets/images/svg-3eme.png', width: 32, height: 32);
    }
    return Text(
      "#$rang", 
      style: GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w700, 
        fontSize: 16,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.read<AppProvider>();
    context.select<AppProvider, String>((p) => p.langue);
    final userId = context.select<AppProvider, dynamic>((p) => p.donneesUtilisateur?['id']);
    
    final theme = Theme.of(context);
    final offsetRang = (_page - 1) * limite;
    final aPageSuivante = _classement.length == limite;
    final aPagePrecedente = _page > 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Row(
            children: [
              Text(
                provider.t("titre_classement"),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _buildBody(theme, provider, offsetRang, userId),
        ),
        
        if (!_erreur && (_classement.isNotEmpty || _page > 1))
          _buildPagination(aPagePrecedente, aPageSuivante, theme, provider),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, AppProvider provider, int offsetRang, dynamic userId) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    
    if (_erreur) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.wifiSlash(), size: 64, color: theme.primaryColor.withOpacity(0.1)),
              const SizedBox(height: 24),
              Text(
                provider.t("err_timeout"), 
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                provider.t("err_check_internet"), 
                style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _chargerClassement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(provider.t("btn_retry"), style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_classement.isEmpty) {
      return Center(child: Text(provider.t("msg_no_players"), style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4))));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _classement.length,
      itemBuilder: (context, index) {
        final joueur = _classement[index];
        final rang = offsetRang + index + 1;
        final estMoi = joueur['id'] == userId;
        final avatarUrl = joueur['photoProfil'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: estMoi ? theme.primaryColor.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: estMoi ? theme.primaryColor.withOpacity(0.1) : Colors.transparent),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: SizedBox(
              width: 80,
              child: Row(
                children: [
                  SizedBox(width: 32, child: Center(child: _buildMedaille(rang, theme))),
                  const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
                          provider.setImageZoomee(avatarUrl);
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) 
                          ? CachedNetworkImageProvider(avatarUrl) 
                          : null,
                        backgroundColor: theme.brightness == Brightness.light ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
                        radius: 20,
                        child: (avatarUrl == null || avatarUrl.isEmpty || !avatarUrl.startsWith('http')) 
                          ? Icon(PhosphorIcons.user(), size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3))
                          : null,
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              joueur['username'] ?? "...",
              style: GoogleFonts.inter(
                fontWeight: estMoi ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
                color: estMoi ? theme.primaryColor : null,
              ),
            ),
            trailing: Text(
              "${joueur['total_score'] ?? 0} PTS",
              style: GoogleFonts.robotoMono(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(bool aPrecedente, bool aSuivante, ThemeData theme, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPagBtn(aPrecedente ? () {
            setState(() => _page--);
            _chargerClassement();
          } : null, PhosphorIcons.caretLeft(), provider.t("btn_prev"), theme),
          
          Text("${provider.t("lbl_page")} $_page", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1)),
          
          _buildPagBtn(aSuivante ? () {
            setState(() => _page++);
            _chargerClassement();
          } : null, PhosphorIcons.caretRight(), provider.t("btn_next"), theme, reversed: true),
        ],
      ),
    );
  }

  Widget _buildPagBtn(VoidCallback? onTap, IconData icon, String label, ThemeData theme, {bool reversed = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!reversed) Icon(icon, size: 16),
              if (!reversed) const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              if (reversed) const SizedBox(width: 8),
              if (reversed) Icon(icon, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
