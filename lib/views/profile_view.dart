import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../components/profile/entete_profil.dart';
import '../components/profile/zone_cadeaux.dart';
import '../components/profile/parametres.dart';
import '../components/profile/community_footer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/pull_to_refresh.dart';

class ProfileView extends StatefulWidget {
  final Future<void> Function() onLogout;

  const ProfileView({super.key, required this.onLogout});

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _modeEdition = false;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final provider = context.read<AppProvider>();
    final userData = provider.donneesUtilisateur;
    final userId = userData?['id'];
    if (userId == null) return;

    try {
      final userFull = await ApiService.obtenirUtilisateur(userId.toString());
      final stats = await ApiService.obtenirStatsUtilisateur(userId.toString());

      final updatedData = Map<String, dynamic>.from(userData ?? {});
      if (userFull is Map<String, dynamic>) updatedData.addAll(userFull);
      if (stats is Map<String, dynamic>) updatedData.addAll(stats);

      provider.setDonneesUtilisateur(updatedData);
    } catch (err) {
      debugPrint("Erreur refresh stats: $err");
    }
  }

  Future<void> _gererUtiliserCode(String code) async {
    final provider = context.read<AppProvider>();

    try {
      // Assuming ApiService has a method for this or using generic post
      final res = await ApiService.creerQuestion(
          {'code': code}); // Placeholder for code redemption
      provider.afficherNotification("Code valide !", type: "succes");
      if (res['user'] != null) {
        provider.setDonneesUtilisateur({
          ...provider.donneesUtilisateur!,
          'total_score': res['user']['total_score']
        });
      }
    } catch (err) {
      provider.afficherNotification("Code invalide", type: "erreur");
    }
  }

  Future<void> _lancerUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.read<AppProvider>();
    final theme = Theme.of(context);

    return CustomScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        MuseRefreshControl(onRefresh: _refreshStats),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              EnteteProfil(
                modeEdition: _modeEdition,
                onToggleEdition: (val) => setState(() => _modeEdition = val),
              ),
              const SizedBox(height: 16),
              if (!_modeEdition)
                ZoneCadeaux(onUtiliserCode: _gererUtiliserCode)
              else ...[
                Parametres(onDeconnexion: widget.onLogout),
                const SizedBox(height: 16),
                const CommunityFooter(),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFooterLink(provider.t("lbl_liens_utiles"),
                      "https://linktr.ee/VisoStudio.co", theme),
                  Text(provider.t("lbl_et"),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.brightness == Brightness.light
                              ? Colors.black
                              : Colors.white)),
                  _buildFooterLink(
                      provider.t("lbl_conditions_utilisations"),
                      "https://daily-muse.fun/conditions/condition.html",
                      theme),
                ],
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text, String url, ThemeData theme) {
    return InkWell(
      onTap: () => _lancerUrl(url),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue,
          ),
        ),
      ),
    );
  }
}
