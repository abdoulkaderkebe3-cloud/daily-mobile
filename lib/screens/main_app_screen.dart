import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../components/nav_bar.dart';
import '../views/home_view.dart';
import '../views/leaderboard_view.dart';
import '../views/profile_view.dart';

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vueActive = provider.vueActive;

    Widget vue;
    if (vueActive == 'classement') {
      vue = const LeaderboardView();
    } else if (vueActive == 'profil') {
      vue = ProfileView(onLogout: () async {
        await ApiService.deconnexion();
        provider.setDonneesUtilisateur(null); // that will re-route to AuthScreen
      });
    } else {
      vue = const HomeView();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: vue),
            const NavBar(),
          ],
        ),
      ),
    );
  }
}
