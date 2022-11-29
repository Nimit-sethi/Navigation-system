import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_maps/mapview.dart';
import 'package:flutter_maps/sessions/welcome_screen.dart';

class Home extends StatelessWidget {
  static const String id = 'home';
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return MapView();
            } else {
              return WelcomeScreen();
            }
          },
        ),
      );

// return WelcomeScreen();
}
