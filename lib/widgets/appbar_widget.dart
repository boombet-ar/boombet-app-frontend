import 'package:boombet_app/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const MainAppBar({super.key, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const greenColor = Color.fromARGB(255, 41, 255, 94);

    return AppBar(
      title: title != null ? Text(title!) : null,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.black38,
      leading: IconButton(
        icon: const Icon(Icons.exit_to_app, color: greenColor),
        tooltip: 'Salir',
        onPressed: () {
          SystemNavigator.pop();
        },
      ),
      actions: [
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
      ],
    );
  }
}
