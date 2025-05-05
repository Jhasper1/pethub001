import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:march24/screen/Shelter_Screen/signin_screen.dart';
import 'signin_screen.dart'; // Import your sign-in screen

class ShelterResetPasswordScreen extends StatefulWidget {
  final String email;

  const ShelterResetPasswordScreen({Key? key, required this.email})
      : super(key: key);

  @override
  _ShelterResetPasswordScreenState createState() =>
      _ShelterResetPasswordScreenState();
}

class _ShelterResetPasswordScreenState
    extends State<ShelterResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _message = '';
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _message = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final url = Uri.parse('http://127.0.0.1:5566/shelter/reset-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'shelter_email': widget.email,
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmPasswordController.text,
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['retCode'] == '200') {
        setState(() => _message = 'Password reset successfully!');
        // Navigate to sign-in screen after a delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        });
      } else {
        setState(() => _message = data['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      setState(() => _message = 'Connection error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset password for ${widget.email}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword),
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Reset Password'),
                    ),
              const SizedBox(height: 16),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: TextStyle(
                    color: _message.toLowerCase().contains('success')
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
