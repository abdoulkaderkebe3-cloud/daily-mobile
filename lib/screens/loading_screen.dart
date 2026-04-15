import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00BFA6)),
            const SizedBox(height: 16),
            Text(
              'Chargement...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
