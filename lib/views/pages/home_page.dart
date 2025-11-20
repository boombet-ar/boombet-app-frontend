import 'package:boombet_app/data/notifiers.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Resetear a la página de Home cuando se carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedPageNotifier.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        Widget currentPage;

        switch (selectedPage) {
          case 0:
            currentPage = const HomeContent();
            break;
          case 1:
            currentPage = const StoreContent();
            break;
          case 2:
            currentPage = const DiscountsContent();
            break;
          case 3:
            currentPage = const RafflesContent();
            break;
          default:
            currentPage = const HomeContent();
        }

        return Scaffold(
          appBar: const MainAppBar(
            showSettings: true,
            showLogo: true,
            showProfileButton: true,
          ),
          body: currentPage,
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'HOME',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class StoreContent extends StatelessWidget {
  const StoreContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;

    return Center(
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
    );
  }
}

class DiscountsContent extends StatelessWidget {
  const DiscountsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.discount, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'DESCUENTOS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class RafflesContent extends StatelessWidget {
  const RafflesContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sort, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'SORTEOS ACTIVOS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
