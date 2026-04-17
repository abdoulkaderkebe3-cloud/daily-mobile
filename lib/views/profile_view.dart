import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../components/profile/entete_profil.dart';
import '../components/profile/zone_cadeaux.dart';
import '../components/profile/parametres.dart';
import '../components/profile/community_footer.dart';

class ProfileView extends StatefulWidget {
  final Future<void> Function() onLogout;

  const ProfileView({super.key, required this.onLogout});

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
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
      final stats = await ApiService.obtenirStatsUtilisateur(userId.toString());
      if (stats is Map<String, dynamic>) {
        final updatedData = Map<String, dynamic>.from(userData ?? {});
        updatedData.addAll(stats);
        provider.setDonneesUtilisateur(updatedData);
      }
    } catch (err) {
      debugPrint("Erreur refresh stats: $err");
    }
  }

  Future<void> _gererUtiliserCode(String code) async {
    final provider = context.read<AppProvider>();

    try {
      // Assuming ApiService has a method for this or using generic post
      final res = await ApiService.creerQuestion({'code': code}); // Placeholder for code redemption
      provider.afficherNotification("Code valide !", type: "succes");
      if (res['user'] != null) {
        provider.setDonneesUtilisateur({...provider.donneesUtilisateur!, 'total_score': res['user']['total_score']});
      }
    } catch (err) {
      provider.afficherNotification("Code invalide", type: "erreur");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
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
        ],
      ),
    );
  }
}
