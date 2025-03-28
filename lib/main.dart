// Filename: main.dart

import 'package:flutter/material.dart';
import 'screen/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetHub',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),   home: SplashScreen(),
    );
  }
}
