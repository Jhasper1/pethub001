import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:march24/screen/UserDashboard/user_verification.dart';

class AdopterForgotPasswordScreen extends StatefulWidget {
  @override
  _AdopterForgotPasswordScreenState createState() =>
      _AdopterForgotPasswordScreenState();
}

class _AdopterForgotPasswordScreenState
    extends State<AdopterForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  Future<void> sendForgotPasswordRequest() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final url = Uri.parse('http://127.0.0.1:5566/adopter/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      setState(() => _isLoading = false);

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if RetCode exists and is valid
        if (responseData != null &&
            (responseData['retCode'] == 200 ||
                responseData['retCode'].toString() == '200')) {
          // Navigate to the verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdopterVerifyResetCodeScreen(email: email),
            ),
          );
        } else {
          // Handle error message from the backend
          setState(() =>
              _message = responseData['Message'] ?? 'Something went wrong.');
        }
      } else {
        // Handle non-200 status codes
        setState(() => _message =
            'Server error: ${response.statusCode}. Please try again.');
      }
    } catch (e) {
      // Handle exceptions (e.g., network issues)
      setState(() {
        _isLoading = false;
        _message = 'An unexpected error occurred. Please try again.';
      });
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address to reset your password.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: const OutlineInputBorder(),
                errorText: _message.isNotEmpty ? _message : null,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: sendForgotPasswordRequest,
                    child: const Text('Send Reset Code'),
                  ),
          ],
        ),
      ),
    );
  }
}
