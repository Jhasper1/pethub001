import 'package:flutter/material.dart';
import 'package:march24/screen/ShelterLogIn/signin_screen.dart';
import 'package:march24/screen/UserLogIn/user_signin.dart';

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
      body: Stack(
        children: [
          // Gradient Background (Blue)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE1F5FE),
                  Color(0xFF448AFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content Column
          Column(
            children: [
              // Top content with image
              Expanded(
                flex: 2, // Increased flex value to give more space to the image
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isAdopterSelected)
                      Positioned(
                        top: 100, // Adjusted position higher up
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
                        top: 100, // Adjusted position higher up
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

              // Bottom card with form elements - made taller
              Expanded(
                flex:2, // Increased flex value to make container taller
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 70, 20, 100), // Increased padding
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 0),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Align content to top
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Join Adopt Me Today",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Adopt This <Tagline>",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 40), // Increased spacing

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildToggleButton("Adopter", isAdopterSelected, () {
                            _toggleSelection(true);
                          }),
                          SizedBox(width: 20), // Increased spacing between buttons
                          _buildToggleButton("Shelter", !isAdopterSelected, () {
                            _toggleSelection(false);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Confirm button positioned at the bottom
          Positioned(
            left: 30,
            right: 30,
            bottom: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B85F3),
                minimumSize: Size(double.infinity, 55), // Slightly taller button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // More rounded corners
                ),
                elevation: 3, // Added shadow
              ),
              onPressed: _navigateToLogin,
              child: Text(
                "Confirm",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18, // Slightly larger text
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF1B85F3) : Color(0xFFB3E5FC),
          minimumSize: Size(150, 55), // Slightly taller buttons
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // More rounded corners
          ),
          elevation: 2, // Added shadow
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF0288D1),
            fontWeight: FontWeight.bold,
            fontSize: 16, // Slightly larger text

          ),
        ),
      ),
    );
  }
}