import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../components/nav_bar.dart';
import '../views/home_view.dart';
import '../views/leaderboard_view.dart';
import '../views/profile_view.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = context.read<AppProvider>();
    _currentIndex = _getIndex(provider.vueActive);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final provider = context.read<AppProvider>();
      if (provider.timerActif) {
        provider.forcerEchecDefi();
        provider.afficherNotification("Vous avez quitté l'application !", type: "erreur");
      }
    }
  }

  int _getIndex(String vue) {
    if (vue == 'classement') return 1;
    if (vue == 'profil') return 2;
    return 0;
  }

  String _getVue(int index) {
    if (index == 1) return 'classement';
    if (index == 2) return 'profil';
    return 'accueil';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final vueActive = context.select<AppProvider, String>((p) => p.vueActive);

    final newIndex = _getIndex(vueActive);
    if (newIndex != _currentIndex && _pageController.hasClients) {
      if (provider.timerActif) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.forcerEchecDefi();
          provider.afficherNotification("Vous avez changé d'onglet !", type: "erreur");
        });
      }
      _currentIndex = newIndex;
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  if (index != _currentIndex) {
                    if (provider.timerActif) {
                      provider.forcerEchecDefi();
                      provider.afficherNotification("Vous avez changé d'onglet !", type: "erreur");
                    }
                  }
                  _currentIndex = index;
                  if (provider.vueActive != _getVue(index)) {
                    provider.changerVue(_getVue(index));
                  }
                },
                children: [
                  const HomeView(),
                  const LeaderboardView(),
                  ProfileView(onLogout: () async {
                    await ApiService.deconnexion();
                    provider.setDonneesUtilisateur(null); // that will re-route to AuthScreen
                  }),
                ],
              ),
            ),
            const NavBar(),
          ],
        ),
      ),
    );
  }
}
