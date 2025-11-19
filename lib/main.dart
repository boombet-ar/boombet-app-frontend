import 'package:boombet_app/data/notifiers.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: .fromSeed(
              seedColor: Colors.black12,
              brightness: isLightMode ? Brightness.light : Brightness.dark,
            ),
          ),
          home: const MyHomePage(title: 'Boombet App'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: LoginPage());
  }
}

//Revisar distribucion de carpetas/archivos
//WidgetTree()
//Hacer diferentes vistas. La de Login (Este archivo) es la inicial
//Link del curso para acceder mas rapido https://www.youtube.com/watch?v=3kaGC_DrUnw
//Reveer ValueListenableBuilder para manejo de estados
