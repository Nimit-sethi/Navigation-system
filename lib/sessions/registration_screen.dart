import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_maps/mapview.dart';
import 'package:flutter_maps/sessions/repeated_button.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import 'package:firebase_core/firebase_core.dart';

import 'constants.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';
  TextEditingController registration = TextEditingController();
  static bool reg_saving = false;
  RegistrationScreen({super.key});
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // late TextEditingController controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String email;
  late String password;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: RegistrationScreen.reg_saving,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Hero(
                tag: 'flash',
                child: Container(
                  height: 150.0,
                  child: Image.asset('images/maps.png'),
                ),
              ),
              const SizedBox(
                height: 48.0,
              ),
              TextField(
                controller: RegistrationScreen().registration,
                // showCursor: false,
                // autofocus: true,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  email = value;
                  //Do something with the user input.
                },
                decoration: kDecoration.copyWith(hintText: 'Enter Your Email'),
              ),
              const SizedBox(
                height: 8.0,
              ),
              TextField(
                obscureText: true,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  password = value;
                  //Do something with the user input.
                },
                decoration:
                    kDecoration.copyWith(hintText: 'Enter your Password'),
              ),
              const SizedBox(
                height: 24.0,
              ),
              RepeatedButton(
                colors: Colors.blueAccent,
                text: 'Register',
                myFunction: () async {
                  setState(() {
                    RegistrationScreen.reg_saving = true;
                  });
                  //Go to registration screen.
                  try {
                    var auth = await _auth.createUserWithEmailAndPassword(
                        email: email, password: password);
                    if (auth != null) {
                      Navigator.pushNamed(context, MapView.id);
                    }
                  } catch (e) {
                    print(e);
                  }
                  setState(() {
                    RegistrationScreen.reg_saving = false;
                  });
                  // controller.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
