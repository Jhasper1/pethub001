import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_signin.dart';

class UserSignUpScreen extends StatefulWidget {
  const UserSignUpScreen({super.key});

  @override
  _UserSignUpScreenState createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController socialController = TextEditingController();

  String? selectedSex;
  String? selectedCivilStatus;
  bool isLoading = false;

  final List<String> sexOptions = ["Male", "Female"];
  final List<String> civilStatusOptions = ["Single", "Married", "Divorced", "Widowed"];

  bool _isValidEmail(String email) {
    return email.endsWith("@gmail.com");
  }

  bool _isValidSocial(String social_media) {
    return social_media.startsWith("@");
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "Contact number is required";
    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "Enter a valid contact number";
    }
    return null;
  }

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://127.0.0.1:5566/user/register');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text,
        "password": passwordController.text,
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "age": ageController.text,
        "sex": selectedSex,
        "address": addressController.text,
        "contact": contactNumberController.text,
        "email": emailController.text,
        "occupation": occupationController.text,
        "civil_status": selectedCivilStatus,
        "social_media": socialController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User registered successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserSignInScreen()),
      );
    } else {
      final errorMessage = jsonDecode(response.body)["error"] ?? "Registration failed";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', width: 35),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Prevent manual swipe
        children: [
          buildStep1(),
          buildStep2(),
        ],
      ),
    );
  }

  // STEP 1: Username & Password
  Widget buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "Username"),
              validator: (value) => value!.isEmpty ? "Username is required" : null,
            ),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
              validator: (value) => value!.isEmpty ? "Password is required" : null,
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
    );
  }

  // STEP 2: Additional User Info
  Widget buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyStep2,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: "First Name"),
                validator: (value) => value!.isEmpty ? "First name is required" : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: "Last Name"),
                validator: (value) => value!.isEmpty ? "Last name is required" : null,
              ),
              TextFormField(
                controller: ageController,
                decoration: InputDecoration(labelText: "Age"),
                validator: (value) => value!.isEmpty ? "Age is required" : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedSex,
                decoration: InputDecoration(labelText: "Sex"),
                items: sexOptions.map((String sex) {
                  return DropdownMenuItem<String>(
                    value: sex,
                    child: Text(sex),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSex = value;
                  });
                },
                validator: (value) => value == null ? "Select a sex" : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: "Address"),
                validator: (value) => value!.isEmpty ? "Address is required" : null,
              ),
              TextFormField(
                controller: contactNumberController,
                decoration: InputDecoration(labelText: "Contact Number"),
                keyboardType: TextInputType.phone,
                validator: validatePhoneNumber,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value != null && !_isValidEmail(value)) ? "Must end with @gmail.com" : null,
              ),
              TextFormField(
                controller: occupationController,
                decoration: InputDecoration(labelText: "Occupation"),
                validator: (value) => value!.isEmpty ? "Occupation is required" : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedCivilStatus,
                decoration: InputDecoration(labelText: "Civil Status"),
                items: civilStatusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCivilStatus = value;
                  });
                },
                validator: (value) => value == null ? "Select a civil status" : null,
              ),
              TextFormField(
                controller: socialController,
                decoration: InputDecoration(labelText: "Social Media"),
                validator: (value) => (value != null && !_isValidSocial(value)) ? "Social media is required" : null,
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
      ),
    );
  }
}
