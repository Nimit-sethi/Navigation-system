import 'package:flutter/material.dart';

class RepeatedButton extends StatelessWidget {
  final Color colors;
  final String text;
  final Function()? myFunction;
  RepeatedButton({
    required this.colors,
    required this.text,
    required this.myFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: colors,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: myFunction,
          minWidth: 200.0,
          height: 42.0,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
