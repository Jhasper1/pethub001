import 'package:flutter/material.dart';
import 'user_signup.dart';
import 'user_signin.dart';

class UserStartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
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
                  Text('PetHub User', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserSignUpScreen())),
                  child: Text('Sign up', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100, minimumSize: Size(250, 50)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserSignInScreen())),
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
