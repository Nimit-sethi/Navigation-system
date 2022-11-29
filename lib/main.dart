import 'dart:collection';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_maps/home.dart';
import 'package:flutter_maps/sessions/login_screen.dart';
import 'package:flutter_maps/sessions/registration_screen.dart';
import 'package:flutter_maps/sessions/welcome_screen.dart';
import 'mapview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: Home.id,
      routes: {
        Home.id: (context) => Home(),
        WelcomeScreen.id: (context) => WelcomeScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        MapView.id: (context) => MapView(),
      },
    );
  }
}
