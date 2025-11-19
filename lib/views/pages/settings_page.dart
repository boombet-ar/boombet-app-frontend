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
    return Scaffold(
      appBar: MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text("TEST PAGE"),
              DropdownButton(
                value: menuItem,
                items: [
                  DropdownMenuItem(value: "e1", child: Text("Elemento 1")),
                  DropdownMenuItem(value: "e2", child: Text("Elemento 2")),
                  DropdownMenuItem(value: "e3", child: Text("Elemento 3")),
                ],
                onChanged: (String? value) {
                  setState(() {
                    menuItem = value;
                  });
                },
              ),
              Checkbox.adaptive(
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked = value ?? false;
                  });
                },
              ),
              CheckboxListTile.adaptive(
                //tristate: le da tres estados al checkbox
                title: Text("Apretame"),
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isChecked = value ?? false;
                  });
                },
              ),
              Switch.adaptive(
                value: isSwitched,
                onChanged: (value) {
                  setState(() {
                    isSwitched = value;
                  });
                },
              ),
              SwitchListTile.adaptive(
                title: Text("Switcheame"),
                value: isSwitched,
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
                onChanged: (double value) {
                  setState(() {
                    sliderValue = value;
                  });
                },
              ),
              InkWell(
                splashColor: Colors.green,
                onTap: () {
                  print("Image selected");
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  color: Colors.white24,
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.black38,
                ),
                child: Text("Clickeame"),
              ),
              ElevatedButton(onPressed: () {}, child: Text("Clickeame")),
              FilledButton(onPressed: () {}, child: Text("Clickeame")),
              TextButton(onPressed: () {}, child: Text("Clickeame")),
              OutlinedButton(onPressed: () {}, child: Text("Clickeame")),
              CloseButton(),
              BackButton(),
            ],
          ),
        ),
      ),
    );
  }
}
