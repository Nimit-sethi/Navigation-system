import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_maps/mapview.dart';
import 'package:flutter_maps/sessions/repeated_button.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'constants.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  static final emailController = TextEditingController();
  static final passController = TextEditingController();
  static bool saving = false;
  LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String email;
  late String password;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: LoginScreen.saving,
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
                // controller: LoginScreen().emailController,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  email = value;
                },
                decoration: kDecoration.copyWith(hintText: 'Enter Your Email'),
              ),
              const SizedBox(
                height: 8.0,
              ),
              TextField(
                // controller: LoginScreen().passController,
                obscureText: true,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  password = value;
                },
                decoration:
                    kDecoration.copyWith(hintText: 'Enter your Password'),
              ),
              const SizedBox(
                height: 24.0,
              ),
              RepeatedButton(
                  text: 'Log In',
                  colors: Colors.lightBlueAccent,
                  myFunction: () async {
                    setState(() {
                      LoginScreen.saving = true;
                    });
                    try {
                      final auth = await _auth.signInWithEmailAndPassword(
                          email: email, password: password);
                      if (auth != null) {
                        Navigator.pushNamed(context, MapView.id);
                      }
                    } catch (e) {
                      Fluttertoast.showToast(
                          msg: "Register First",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          // backgroundColor: Colors.red,
                          // textColor: Colors.white,
                          fontSize: 16.0);
                    }
                    setState(() {
                      LoginScreen.saving = false;
                    });
                  }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
