import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
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
                  const SizedBox(height: 10),
                  const Text('PetHub', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(250, 50),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: const Text('Sign up', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    minimumSize: const Size(250, 50),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  child: const Text('Sign in', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
