import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:march24/screen/Shelter_Screen/signin_screen.dart';
import 'package:march24/screen/UserDashboard/user_signin.dart';

class ChooseUserScreen extends StatefulWidget {
  const ChooseUserScreen({super.key});

  @override
  _ChooseUserScreenState createState() => _ChooseUserScreenState();
}

class _ChooseUserScreenState extends State<ChooseUserScreen>
    with SingleTickerProviderStateMixin {
  bool isAdopterSelected = true;

  late AnimationController _animationController;
  late Animation<Offset> _cardAnimation;
  late Animation<Offset> _imageAnimation;
  late Animation<double> _imageFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));

    // Card animates first
    _cardAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    // Dog image animates after card
    _imageAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _imageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  void _toggleSelection(bool adopterSelected) {
    setState(() {
      isAdopterSelected = adopterSelected;
    });

    // Navigate without transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
        adopterSelected ? UserSignInScreen() : SignInScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
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
          /// Background Gradient
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

          /// Dog PNG Animation
          FadeTransition(
            opacity: _imageFadeAnimation,
            child: SlideTransition(
              position: _imageAnimation,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Image.asset(
                    'assets/images/splash.png',
                    width: 500,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          /// Bottom Card UI Animation
          SlideTransition(
            position: _cardAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.40,
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
                      "Join PetHub today!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Every Paw Deserves a Home 🐾",
                      style: GoogleFonts.poppins(
                        color: Colors.lightBlue.shade500,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isSelected ? Colors.lightBlue : Colors.blue.shade50,
          minimumSize: Size(150, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.lightBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}