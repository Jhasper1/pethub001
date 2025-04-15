import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;


Future<void> _login() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final url = Uri.parse('http://127.0.0.1:5566/shelter/login');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final data = responseData['data'];
      if (data != null && data['shelter_id'] != null) {
        final int shelterId = data['shelter_id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(shelterId: shelterId)),
        );
      } else {
        setState(() => _errorMessage = "Login failed. Please try again.");
      }
    } else {
      // Show specific error message from the backend (like "Your account is pending...")
      setState(() => _errorMessage = responseData['message'] ?? "Login failed. Please try again.");
    }
  } catch (e) {
    setState(() => _errorMessage = "Server error. Please try again later.");
  } finally {
    setState(() => _isLoading = false);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2F3FD), // light blue background
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Image.asset('assets/images/logo.png', width: 150),
                          const SizedBox(height: 20),
                          const Text(
                            'Sign in as Adopter Account',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your username',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(value: false, onChanged: (val) {}),
                                  const Text('Remember me'),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(color: Color(0xFF0288D1)),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0288D1),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _login,
                            child: const Text(
                              'Sign in',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Sign up",
                        style: TextStyle(color: Color(0xFF0288D1)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
