import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      appBar: const MainAppBar(
        showSettings: true,
        showLogo: true,
        showProfileButton: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'TIENDA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NavbarWidget(),
    );
  }
}
