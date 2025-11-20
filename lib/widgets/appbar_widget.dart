import 'package:boombet_app/data/notifiers.dart';
import 'package:boombet_app/views/pages/profile_page.dart';
import 'package:boombet_app/views/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showSettings;
  final bool showLogo;
  final bool showBackButton;
  final bool showProfileButton;

  const MainAppBar({
    super.key,
    this.title,
    this.showSettings = false,
    this.showLogo = false,
    this.showBackButton = false,
    this.showProfileButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const greenColor = Color.fromARGB(255, 41, 255, 94);

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.black38,
      leading: null,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            icon: Icon(
              showBackButton ? Icons.arrow_back : Icons.exit_to_app,
              color: greenColor,
            ),
            tooltip: showBackButton ? 'Volver' : 'Salir',
            onPressed: () {
              if (showBackButton) {
                Navigator.of(context).pop();
              } else {
                SystemNavigator.pop();
              }
            },
          ),
          if (showSettings)
            IconButton(
              icon: const Icon(Icons.settings, color: greenColor),
              tooltip: 'Configuración',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return SettingsPage();
                    },
                  ),
                );
              },
            ),
          if (showProfileButton)
            IconButton(
              icon: const Icon(Icons.person, color: greenColor),
              tooltip: "Perfil",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ProfilePage();
                    },
                  ),
                );
              },
            ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: isLightModeNotifier,
              builder: (context, isLightMode, child) {
                return Icon(
                  isLightMode ? Icons.dark_mode : Icons.light_mode,
                  color: greenColor,
                );
              },
            ),
            tooltip: "Modo Claro",
            onPressed: () {
              isLightModeNotifier.value = !isLightModeNotifier.value;
            },
          ),
          Spacer(),
          if (showLogo)
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Image.asset('assets/images/boombetlogo.png', height: 80),
            ),
        ],
      ),
      actions: [],
    );
  }
}
