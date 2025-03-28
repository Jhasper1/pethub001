import 'package:flutter/material.dart';
import 'package:march24/screen/UserDashboard/user_dashboard.dart';
import '../home_screen.dart';

class UserSignInScreen extends StatefulWidget {
  @override
  _UserSignInScreenState createState() => _UserSignInScreenState();
}

class _UserSignInScreenState extends State<UserSignInScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isButtonEnabled = false;
  bool isChecked = false;

  void checkFields() {
    setState(() {
      isButtonEnabled = usernameController.text.isNotEmpty && passwordController.text.isNotEmpty && isChecked;
    });
  }

  @override
  void initState() {
    super.initState();
    usernameController.addListener(checkFields);
    passwordController.addListener(checkFields);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', width: 35),
        leading: BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign in', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Username')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked = value!;
                      checkFields();
                    });
                  },
                ),
                Text('Remember me')
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: Size(double.infinity, 50)),
              onPressed: isButtonEnabled ? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserDashboard())) : null,
              child: Text('Sign in', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
