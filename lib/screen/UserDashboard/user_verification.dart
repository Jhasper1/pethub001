import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'user_reset_password.dart';

class AdopterVerifyResetCodeScreen extends StatefulWidget {
  final String email;

  const AdopterVerifyResetCodeScreen({super.key, required this.email});

  @override
  State<AdopterVerifyResetCodeScreen> createState() =>
      _AdopterVerifyResetCodeScreenState();
}

class _AdopterVerifyResetCodeScreenState
    extends State<AdopterVerifyResetCodeScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  String _message = '';
  bool _isLoading = false;
  bool _isResending = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _codeControllers[i].text.isEmpty) {
          if (i > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _fieldFocusChange(BuildContext context, int currentIndex, String value) {
    if (value.length == 1 && currentIndex < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[currentIndex + 1]);
    } else if (value.isEmpty && currentIndex > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[currentIndex - 1]);
    }
  }

  Future<void> verifyCode() async {
    final fullCode = _codeControllers.map((c) => c.text).join();

    if (fullCode.length != 6) {
      setState(() {
        _message = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final url = Uri.parse("http://127.0.0.1:5566/adopter/verify-code");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'code': fullCode,
          'type': 'forgot-password',
          'prefilter': 'verify-code',
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      bool isSuccess = (response.statusCode == 200) &&
          (data['retCode'] == "200" ||
              data['success'] == true ||
              data['Message']?.toLowerCase().contains('success') == true ||
              data['status'] == 'ok');

      if (isSuccess) {
        debugPrint('Verification successful!');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdopterResetPasswordScreen(email: widget.email),
          ),
        );
      } else {
        final errorMsg =
            data['message'] ?? data['error'] ?? 'Verification failed.';
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

  Future<void> resendCode() async {
    setState(() {
      _isResending = true;
      _message = '';
    });

    try {
      final url = Uri.parse('http://127.0.0.1:5566/adopter/forgot-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      debugPrint('Resend Status Code: ${response.statusCode}');
      debugPrint('Resend Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData != null &&
            (responseData['retCode'] == 200 ||
                responseData['retCode'].toString() == '200')) {
          setState(() => _message = 'Verification code resent successfully!');

          for (var controller in _codeControllers) {
            controller.clear();
          }
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        } else {
          setState(() => _message = responseData['Message'] ??
              'Failed to resend code. Please try again.');
        }
      } else {
        setState(() => _message =
            'Server error: ${response.statusCode}. Please try again.');
      }
    } catch (e) {
      setState(
          () => _message = 'An unexpected error occurred. Please try again.');
      debugPrint("Resend Exception: $e");
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP Code"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Enter the 6-digit code sent to your email',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    child: TextFormField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        _fieldFocusChange(context, index, value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: verifyCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Verify Code"),
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
            const SizedBox(height: 20),
            _isResending
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: resendCode,
                    child: const Text("Didn't receive code? Resend"),
                  ),
          ],
        ),
      ),
    );
  }
}
