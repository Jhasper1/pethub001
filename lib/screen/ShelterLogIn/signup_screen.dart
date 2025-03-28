import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController shelterNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();

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

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://localhost:8080/register');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text,
        "password": passwordController.text,
        "shelter_name": shelterNameController.text,
        "address": addressController.text,
        "contact": contactNumberController.text,
        "email": emailController.text,
        "owner_name": ownerNameController.text,
        "sex": selectedSex,
        "civil_status": selectedCivilStatus,
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
        MaterialPageRoute(builder: (_) => SignInScreen()),
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
                controller: shelterNameController,
                decoration: InputDecoration(labelText: "Shelter Name"),
                validator: (value) => value!.isEmpty ? "Shelter name is required" : null,
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
                controller: ownerNameController,
                decoration: InputDecoration(labelText: "Owner's Name"),
                validator: (value) => value!.isEmpty ? "Owner's name is required" : null,
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
