import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController shelterNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();
  final TextEditingController profileController = TextEditingController();
  final TextEditingController coverController = TextEditingController();

  String? selectedSex;
  String? selectedCivilStatus;
  bool isLoading = false;

  final List<String> sexOptions = ["Male", "Female"];
  final List<String> civilStatusOptions = ["Single", "Married", "Divorced", "Widowed"];

  bool _isValidEmail(String email) {
    return email.endsWith("@gmail.com");
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "Contact number is required";
    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "Enter a valid contact number";
    }
    return null;
  }

  String? validatePasswordMatch(String? value) {
    if (value == null || value.isEmpty) {
      return "Confirm password is required";
    } else if (value != passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://127.0.0.1:5566/shelter/register');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text,
        "password": passwordController.text,
        "shelter_name": shelterNameController.text,
        "shelter_address": addressController.text,
        "shelter_landmark": landmarkController.text,
        "shelter_contact": contactNumberController.text,
        "shelter_email": emailController.text,
        "shelter_owner": ownerNameController.text,
        "shelter_description": descriptionController.text,
        "shelter_social": socialMediaController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Shelter registered successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SignInScreen()),
      );
    } else {
      final errorMessage = jsonDecode(response.body)["message"] ?? "Registration failed";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Adjust height
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 150),
                  const SizedBox(height: 20),
                  const Text(
                    'Sign up as Shelter Account',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Prevent manual swipe
                children: [
                  buildStep1(),
                  buildStep2(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Additional User Info
  Widget buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyStep1,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shelter Name', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: shelterNameController,
                decoration: _inputDecoration("Enter shelter name"),
                validator: (value) => value!.isEmpty ? "Shelter name is required" : null,
              ),
              SizedBox(height: 10),
              const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: addressController,
                decoration: _inputDecoration("Enter address"),
                validator: (value) => value!.isEmpty ? "Address is required" : null,
              ),
              SizedBox(height: 10),
              const Text('Landmark', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: landmarkController,
                decoration: _inputDecoration("Enter landmark"),
                validator: (value) => value!.isEmpty ? "Landmark is required" : null,
              ),
              SizedBox(height: 10),
              const Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: contactNumberController,
                decoration: _inputDecoration("Enter contact number"),
                keyboardType: TextInputType.phone,
                validator: validatePhoneNumber,
              ),
              SizedBox(height: 10),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: emailController,
                decoration: _inputDecoration("Enter email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value != null && !_isValidEmail(value)) ? "Must end with @gmail.com" : null,
              ),
              SizedBox(height: 10),
              const Text('Owner\'s Name', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: ownerNameController,
                decoration: _inputDecoration("Enter owner's name"),
                validator: (value) => value!.isEmpty ? "Owner's name is required" : null,
              ),
              SizedBox(height: 10),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: descriptionController,
                decoration: _inputDecoration("Enter description"),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? "Description is required" : null,
              ),
              SizedBox(height: 10),
              const Text('Social Media', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: socialMediaController,
                decoration: _inputDecoration("Enter social media link"),
                validator: (value) => value!.isEmpty ? "Social media link is required" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {
                  if (_formKeyStep1.currentState!.validate()) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text("Next", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 2: Username & Password
  Widget buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: usernameController,
              decoration: _inputDecoration("Enter username"),
              validator: (value) => value!.isEmpty ? "Username is required" : null,
            ),
            SizedBox(height: 10),
            const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: passwordController,
              decoration: _inputDecoration("Enter password"),
              obscureText: true,
              validator: (value) => value!.isEmpty ? "Password is required" : null,
            ),
            SizedBox(height: 10),
            const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: confirmPasswordController,
              decoration: _inputDecoration("Confirm password"),
              obscureText: true,
              validator: validatePasswordMatch,
            ),
            SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.orange,
              ),
              onPressed: () async {
                if (_formKeyStep2.currentState!.validate()) {
                  await registerUser();
                }
              },
              child: Text("Sign Up", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
