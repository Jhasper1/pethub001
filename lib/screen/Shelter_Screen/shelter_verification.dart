import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // for debugPrint

import 'shelter_reset_password.dart';

class ShelterVerifyResetCodeScreen extends StatefulWidget {
  final String email;

  const ShelterVerifyResetCodeScreen({required this.email});

  @override
  State<ShelterVerifyResetCodeScreen> createState() =>
      _ShelterVerifyResetCodeScreenState();
}

class _ShelterVerifyResetCodeScreenState
    extends State<ShelterVerifyResetCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _message = '';
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse("http://127.0.0.1:5566/shelter/verify-code");

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'shelter_email': widget.email,
          'code': _codeController.text.trim(),
          'type': 'forgot-password',
          'prefilter': 'verify-code',
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      // Check for success using the exact field name from response ("retCode")
      bool isSuccess = (response.statusCode == 200) &&
          (data['retCode'] ==
                  "200" || // Note: "200" is a string in the response
              data['success'] == true ||
              data['Message']?.toLowerCase().contains('success') == true ||
              data['status'] == 'ok');

      if (isSuccess) {
        debugPrint('Verification successful!');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShelterResetPasswordScreen(email: widget.email),
          ),
        );
      } else {
        final errorMsg =
            data['message'] ?? // Also using lowercase to match response
                data['error'] ??
                'Verification failed. Please check the code and try again.';
        setState(() => _message = errorMsg);
        debugPrint('Verification failed: $errorMsg');
      }
    } catch (e) {
      setState(() => _message = 'Connection error. Please check your network.');
      debugPrint('Error during verification: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Code")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: "Verification Code",
                  border: OutlineInputBorder(),
                  hintText: "Enter the 6-digit code",
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: verifyCode,
                      child: const Text("Verify Code"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: TextStyle(
                    color: _message.toLowerCase().contains('fail') ||
                            _message.toLowerCase().contains('error') ||
                            _message.toLowerCase().contains('invalid')
                        ? Colors.red
                        : Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
