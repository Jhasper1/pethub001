// Filename: signup_screen.dart

import 'package:flutter/material.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController shelterNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isButtonEnabled() {
    return shelterNameController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        contactNumberController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        ownerNameController.text.isNotEmpty &&
        usernameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PetHub"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                controller: shelterNameController,
                decoration: InputDecoration(labelText: "Shelter Name"),
                onChanged: (text) => setState(() {}),
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
              ),
              TextFormField(
                controller: ownerNameController,
                decoration: InputDecoration(labelText: "Owner's Name"),
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
                  backgroundColor: isButtonEnabled() ? Colors.orange : Colors.grey,
                ),
                onPressed: isButtonEnabled()
                    ? () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignInScreen()),
                  );
                }
                    : null,
                child: Text("Sign Up", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
