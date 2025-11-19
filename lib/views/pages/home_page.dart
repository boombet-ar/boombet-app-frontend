import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        showSettings: true,
        showLogo: true,
        showProfileButton: true,
      ),
      body: Center(
        child: Container(
          color: Colors.black38,
          height: double.infinity,
          width: double.infinity,
          padding: const EdgeInsets.all(25.0),
        ),
      ),
      bottomNavigationBar: NavbarWidget(),
    );
  }
}
