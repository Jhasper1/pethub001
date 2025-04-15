import 'package:flutter/material.dart';
import 'package:march24/screen/Shelter_Screen/signin_screen.dart';
import 'package:march24/screen/UserLogIn/user_signin.dart';
import 'UserLogin/user_start_screen.dart';

class ChooseUserScreen extends StatefulWidget {
  const ChooseUserScreen({super.key});

  @override
  _ChooseUserScreenState createState() => _ChooseUserScreenState();
}

class _ChooseUserScreenState extends State<ChooseUserScreen>
    with SingleTickerProviderStateMixin {
  bool isAdopterSelected = true;
  late AnimationController _animationController;
  late Animation<Offset> _imageAnimation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    _imageAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _toggleSelection(bool adopterSelected) {
    setState(() {
      isAdopterSelected = adopterSelected;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isAdopterSelected ? UserSignInScreen() : SignInScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Blue Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlue.shade50,
                    Colors.blueAccent,
                  ],
                ),
              ),
            ),
          ),

          /// Foreground Content
          Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isAdopterSelected)
                      Positioned(
                        top: 150,
                        left: 40,
                        right: 40,
                        child: SlideTransition(
                          position: _imageAnimation,
                          child: Image.asset(
                            'assets/images/adopter.png',
                            width: 300,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    if (!isAdopterSelected)
                      Positioned(
                        top: 135,
                        left: 20,
                        right: 20,
                        child: SlideTransition(
                          position: _imageAnimation,
                          child: Image.asset(
                            'assets/images/shelter.png',
                            width: 280,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              /// Bottom Card UI
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 30),
                    Text(
                      "Join Adopt Me Today",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Adopt This <Tagline>",
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToggleButton("Adopter", isAdopterSelected, () {
                          _toggleSelection(true);
                        }),
                        SizedBox(width: 10),
                        _buildToggleButton("Shelter", !isAdopterSelected, () {
                          _toggleSelection(false);
                        }),
                      ],
                    ),
                    SizedBox(height: 40),
                    /// Confirm Button - Now matches toggle button size
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          minimumSize: Size(double.infinity, 50),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _navigateToLogin,
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method to create toggle buttons
  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue.shade700 : Colors.blue.shade50,
          minimumSize: Size(150, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.blue.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}