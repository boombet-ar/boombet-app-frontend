import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: Colors.black12,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Boombet App'),
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: Colors.black38,
        ),
        drawer: Drawer(
          child: Column(
            children: [
              ListTile(title: Text("Salir"), leading: Icon(Icons.exit_to_app)),
            ],
          ),
        ),
        body: Center(
          child: Container(
            color: Colors.black38,
            height: double.infinity,
            width: double.infinity,
            padding: const EdgeInsets.all(25.0),
            child: Center(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // const SizedBox(height: 16),
                      Image.asset('assets/images/boombetlogo.png', width: 200),
                      // const Center(child: Text("Iniciar Sesion")),
                      SizedBox(
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Usuario',
                          ),
                        ),
                      ),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Contraseña',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//Revisar distribucion de carpetas/archivos
//WidgetTree()
//Hacer diferentes vistas. La de Login (Este archivo) es la inicial
//Link del curso para acceder mas rapido https://www.youtube.com/watch?v=3kaGC_DrUnw
//Reveer ValueListenableBuilder para manejo de estados
