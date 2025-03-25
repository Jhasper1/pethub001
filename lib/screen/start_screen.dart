import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', width: 150),
                  SizedBox(height: 10),
                  Text('PetHub', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: Size(250, 50)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpScreen())),
                  child: Text('Sign up', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100, minimumSize: Size(250, 50)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen())),
                  child: Text('Sign in', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
