import 'package:flutter/material.dart';
import 'user_signin.dart';

class UserSignUpScreen extends StatefulWidget {
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
        selectedCivilStatus != null &&
        _isValidEmail(emailController.text);
  }

  bool _isValidEmail(String email) {
    return email.endsWith("@gmail.com");
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
                Text('Sign up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),

                /// First Name
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: "First Name"),
                  onChanged: (text) => setState(() {}),
                ),

                /// Last Name
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: "Last Name"),
                  onChanged: (text) => setState(() {}),
                ),

                /// Age (Numbers Only)
                TextFormField(
                  controller: ageController,
                  decoration: InputDecoration(labelText: "Age"),
                  keyboardType: TextInputType.number,
                  onChanged: (text) => setState(() {}),
                ),

                /// Sex Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Sex"),
                  value: selectedSex,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSex = newValue;
                    });
                  },
                  items: ["Male", "Female"]
                      .map((sex) => DropdownMenuItem(value: sex, child: Text(sex)))
                      .toList(),
                ),

                /// Address
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: "Address"),
                  onChanged: (text) => setState(() {}),
                ),

                /// Contact Number (Numbers Only)
                TextFormField(
                  controller: contactNumberController,
                  decoration: InputDecoration(labelText: "Contact Number"),
                  keyboardType: TextInputType.phone,
                  onChanged: (text) => setState(() {}),
                ),

                /// Email (Validation for "@gmail.com")
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (text) => setState(() {}),
                  validator: (value) {
                    if (value != null && !_isValidEmail(value)) {
                      return "Email must end with @gmail.com";
                    }
                    return null;
                  },
                ),

                /// Occupation
                TextFormField(
                  controller: occupationController,
                  decoration: InputDecoration(labelText: "Occupation"),
                  onChanged: (text) => setState(() {}),
                ),

                /// Civil Status Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Civil Status"),
                  value: selectedCivilStatus,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCivilStatus = newValue;
                    });
                  },
                  items: ["Single", "Married", "Divorced", "Widowed"]
                      .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                ),

                /// Social Media
                TextFormField(
                  controller: socialMediaController,
                  decoration: InputDecoration(labelText: "Social Media"),
                  onChanged: (text) => setState(() {}),
                ),

                /// Username
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: "Username"),
                  onChanged: (text) => setState(() {}),
                ),

                /// Password
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: "Password"),
                  obscureText: true,
                  onChanged: (text) => setState(() {}),
                ),

                SizedBox(height: 20),

                /// Sign-Up Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: isButtonEnabled() ? Colors.orange : Colors.grey,
                  ),
                  onPressed: isButtonEnabled()
                      ? () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => UserSignInScreen()),
                      );
                    }
                  }
                      : null,
                  child: Text("Sign Up", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
