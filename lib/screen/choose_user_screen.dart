import 'package:flutter/material.dart';
import 'package:march24/screen/ShelterLogIn/signin_screen.dart';
import 'package:march24/screen/UserLogIn/user_signin.dart';

/// Import the new login screens
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
      begin: Offset(0, 1), // Start position (off-screen bottom)
      end: Offset(0, 0), // End position (on-screen)
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
    /// Navigate based on selection
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
          /// Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
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
                        top: 150, // Adjust position for adopter.png
                        left: 40,
                        right: 40,
                        child: SlideTransition(
                          position: _imageAnimation,
                          child: Image.asset(
                            'assets/images/adopter.png',
                            width: 300, // Adjust size as needed
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    if (!isAdopterSelected)
                      Positioned(
                        top: 135, // Adjust position for shelter.png
                        left: 20,
                        right: 20,
                        child: SlideTransition(
                          position: _imageAnimation,
                          child: Image.asset(
                            'assets/images/shelter.png',
                            width: 280, // Adjust size as needed
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
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Join Adopt Me Today",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text("Adopt This <Tagline>", style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 20),

                    /// Buttons to toggle selection
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

                    SizedBox(height: 20),

                    /// Confirm Button - Navigates to corresponding login screen
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: _navigateToLogin, // Calls the navigation function
                      child: Text("Confirm", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
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
          backgroundColor: isSelected ? Colors.orange : Colors.orange.shade100,
          minimumSize: Size(150, 50),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.orange),
        ),
      ),
    );
  }
}
