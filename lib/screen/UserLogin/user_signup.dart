import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_signin.dart';

class UserSignUpScreen extends StatefulWidget {
  const UserSignUpScreen({super.key});

  @override
  _UserSignUpScreenState createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedSex;
  String? selectedCivilStatus;
  bool isLoading = false;
  final String apiUrl = "http://127.0.0.1:5566/user/register";

  bool isButtonEnabled() {
    return firstNameController.text.isNotEmpty &&
        lastNameController.text.isNotEmpty &&
        ageController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        contactNumberController.text.isNotEmpty &&
        occupationController.text.isNotEmpty &&
        socialMediaController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        selectedSex != null &&
        selectedCivilStatus != null;
  }

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(apiUrl);
    final Map<String, dynamic> userData = {
      "first_name": firstNameController.text,
      "last_name": lastNameController.text,
      "age": int.tryParse(ageController.text) ?? 0,
      "sex": selectedSex,
      "address": addressController.text,
      "contact_number": int.tryParse(contactNumberController.text),
      "email": emailController.text,
      "occupation": occupationController.text,
      "civil_status": selectedCivilStatus,
      "social_media": socialMediaController.text,
      "username": usernameController.text,
      "password": passwordController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        // Registration success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration Successful!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserSignInScreen()),
        );
      } else {
        // Registration failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign up',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: "First Name"),
                  onChanged: (text) => setState(() {}),
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: "Last Name"),
                  onChanged: (text) => setState(() {}),
                ),
                TextFormField(
                  controller: ageController,
                  decoration: InputDecoration(labelText: "Age"),
                  keyboardType: TextInputType.number,
                  onChanged: (text) => setState(() {}),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Sex"),
                  value: selectedSex,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSex = newValue;
                    });
                  },
                  items: ["Male", "Female"]
                      .map((sex) =>
                          DropdownMenuItem(value: sex, child: Text(sex)))
                      .toList(),
                ),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: "Address"),
                  onChanged: (text) => setState(() {}),
                ),
                TextFormField(
                  controller: contactNumberController,
                  decoration: InputDecoration(labelText: "Contact Number"),
                  keyboardType: TextInputType.phone,
                  onChanged: (text) => setState(() {}),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (text) => setState(() {}),
                  validator: (value) {
                    if (value == null || !value.contains("@")) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: occupationController,
                  decoration: InputDecoration(labelText: "Occupation"),
                  onChanged: (text) => setState(() {}),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Civil Status"),
                  value: selectedCivilStatus,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCivilStatus = newValue;
                    });
                  },
                  items: ["Single", "Married", "Divorced", "Widowed"]
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                ),
                TextFormField(
                  controller: socialMediaController,
                  decoration: InputDecoration(labelText: "Social Media"),
                  onChanged: (text) => setState(() {}),
                ),
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: "Username"),
                  onChanged: (text) => setState(() {}),
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: "Password"),
                  obscureText: true,
                  onChanged: (text) => setState(() {}),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor:
                        isButtonEnabled() ? Colors.orange : Colors.grey,
                  ),
                  onPressed:
                      isButtonEnabled() && !isLoading ? registerUser : null,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Sign Up", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

