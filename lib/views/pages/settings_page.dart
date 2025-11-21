import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isChecked = false;
  bool isSwitched = false;
  double sliderValue = 0.0;
  String? menuItem = "e1";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onBackground;
    final surfaceColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE8E8E8);

    return Scaffold(
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
      ),
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  "TEST PAGE",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton(
                  dropdownColor: surfaceColor,
                  value: menuItem,
                  items: [
                    DropdownMenuItem(
                      value: "e1",
                      child: Text(
                        "Elemento 1",
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "e2",
                      child: Text(
                        "Elemento 2",
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "e3",
                      child: Text(
                        "Elemento 3",
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      menuItem = value;
                    });
                  },
                ),
                Checkbox.adaptive(
                  value: isChecked,
                  activeColor: primaryGreen,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked = value ?? false;
                    });
                  },
                ),
                CheckboxListTile.adaptive(
                  title: Text("Apretame", style: TextStyle(color: textColor)),
                  value: isChecked,
                  activeColor: primaryGreen,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked = value ?? false;
                    });
                  },
                ),
                Switch.adaptive(
                  value: isSwitched,
                  activeColor: primaryGreen,
                  onChanged: (value) {
                    setState(() {
                      isSwitched = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  title: Text("Switcheame", style: TextStyle(color: textColor)),
                  value: isSwitched,
                  activeColor: primaryGreen,
                  onChanged: (value) {
                    setState(() {
                      isSwitched = value;
                    });
                  },
                ),
                Slider.adaptive(
                  max: 10.0,
                  divisions: 10,
                  value: sliderValue,
                  activeColor: primaryGreen,
                  inactiveColor: isDark ? Colors.white24 : Colors.black26,
                  onChanged: (double value) {
                    setState(() {
                      sliderValue = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                InkWell(
                  splashColor: primaryGreen,
                  onTap: () {},
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    color: surfaceColor,
                    alignment: Alignment.center,
                    child: Text(
                      "Clickeame",
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                  child: const Text("Clickeame"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const LoginPage();
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isDark
                        ? Colors.black
                        : const Color(0xFF2C2C2C),
                  ),
                  child: const Text("Cerrar Sesion"),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: primaryGreen),
                  child: Text(
                    "Clickeame",
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Clickeame",
                    style: TextStyle(color: primaryGreen),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryGreen),
                  ),
                  child: Text(
                    "Clickeame",
                    style: TextStyle(color: primaryGreen),
                  ),
                ),
                const CloseButton(),
                const BackButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
