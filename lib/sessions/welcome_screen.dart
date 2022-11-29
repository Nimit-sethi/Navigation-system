import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_maps/sessions/registration_screen.dart';
import 'package:flutter_maps/sessions/repeated_button.dart';

import 'login_screen.dart';
// import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  static const String id = 'welcome_screen';

  const WelcomeScreen({super.key});
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation animation;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    controller.forward();
    animation =
        ColorTween(begin: Colors.black, end: Colors.white).animate(controller);
    controller.addListener(() {
      setState(() {});
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animation.value,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Hero(
                    tag: 'flash',
                    child: Container(
                      height: 60.0,
                      child: Image.asset('images/maps.png'),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: AnimatedTextKit(
                      isRepeatingAnimation: false,
                      // pause: Duration(seconds: 1),

                      animatedTexts: [
                        TypewriterAnimatedText(
                          'Map For Navigation',
                          textStyle: const TextStyle(
                            color: Colors.black,
                            // fontSize: ,
                            fontWeight: FontWeight.w900,
                          ),
                          speed: const Duration(milliseconds: 100),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 48.0,
            ),
            RepeatedButton(
                text: 'Log In',
                colors: Colors.lightBlueAccent,
                myFunction: () {
                  LoginScreen.emailController.clear();
                  LoginScreen.passController.clear();
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          // transitionDuration: const Duration(milliseconds: 600),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  LoginScreen()));
                }),
            RepeatedButton(
              colors: Colors.blueAccent,
              text: 'Register',
              myFunction: () {
                RegistrationScreen().registration.clear();
                //Go to registration screen.
                Navigator.pushNamed(context, RegistrationScreen.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();
    super.dispose();
  }
}
