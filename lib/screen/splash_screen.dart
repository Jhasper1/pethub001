// Filename: splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'choose_user_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChooseUserScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade50, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Top Image
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Image.asset(
                '/images/logo.png',
                width: 150,
                height: 150,
              ),
            ),

            // Splash Image
            Positioned(
              top: 300,
              left: 0,
              right: 40,
              child: Image.asset(
                '/images/splash.png',
                width: 700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
