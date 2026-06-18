import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../components/pull_to_refresh.dart';

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
  String _typeErreur = "";
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _chargerClassement();
  }

  Future<void> _chargerClassement({bool isRefresh = false}) async {
    final provider = context.read<AppProvider>();

    // Toujours réinitialiser l'erreur dès qu'on tente un chargement
    if (mounted) {
      setState(() {
        _typeErreur = "";
        if (!isRefresh) _chargement = true;
      });
    }

    // Afficher le cache immédiatement si disponible (premier chargement seulement)
    if (!isRefresh && provider.cacheClassement != null && _page == 1) {
      if (mounted) {
        setState(() {
          _classement = provider.cacheClassement!;
          _chargement = false;
        });
      }
      // On ne fait PAS de return ici pour rafraîchir en arrière-plan
    }

    try {
      final rep = await ApiService.obtenirUtilisateurs(page: _page, limite: limite)
          .timeout(const Duration(seconds: 30));

      final liste = rep['users'] ?? rep['data'] ?? [];
      if (mounted) {
        setState(() {
          _classement = liste;
          _typeErreur = "";
          if (_page == 1) provider.setCacheClassement(liste);
          _chargement = false;
        });
      }
    } catch (e) {
      // Afficher l'erreur que le classement soit vide ou non (ex: après reconnexion)
      if (mounted) {
        setState(() {
          if (e.toString().contains("SocketException") ||
              e.toString().contains("Failed host lookup") ||
              e.toString().contains("TimeoutException") ||
              e.toString().contains("ClientException") ||
              e.toString().contains("XMLHttpRequest error")) {
            _typeErreur = "internet";
          } else {
            _typeErreur = "backend";
          }
          _chargement = false;
        });
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
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              MuseRefreshControl(onRefresh: () async {
                await _chargerClassement(isRefresh: true);
              }),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                sliver: SliverToBoxAdapter(
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
              ),
              ..._buildSlivers(theme, provider, offsetRang, userId),
            ],
          ),
        ),
        
        if (_typeErreur.isEmpty && (_classement.isNotEmpty || _page > 1))
          _buildPagination(aPagePrecedente, aPageSuivante, theme, provider),
      ],
    );
  }

  List<Widget> _buildSlivers(ThemeData theme, AppProvider provider, int offsetRang, dynamic userId) {
    if (_chargement) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))];
    }
    
    if (_typeErreur.isNotEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.wifiSlash(), size: 64, color: theme.primaryColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 24),
                  Text(
                    provider.t("err_timeout"), 
                    style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _typeErreur == "internet" ? provider.t("err_check_internet") : provider.t("err_backend_unavailable"), 
                    style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        )
      ];
    }

    if (_classement.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(provider.t("msg_no_players"), style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)))),
        )
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
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
    )
    )
    ];
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
