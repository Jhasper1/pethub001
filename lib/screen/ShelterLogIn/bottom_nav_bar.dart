import 'package:flutter/material.dart';
import 'package:march24/screen/ShelterLogIn/home_screen.dart';
import 'profile_screen.dart'; // Import ProfileScreen
import 'view_pets.dart';
import 'add_pet.dart';

class BottomNavBar extends StatelessWidget {
  final int shelterId; // Add shelterId as a parameter
  final int currentIndex; // Add currentIndex to track the active tab

  const BottomNavBar({super.key, required this.shelterId, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Disable slide animation
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false, // Hide labels for inactive pages
      currentIndex: currentIndex, // Set the active tab
      onTap: (index) {
        if (index == currentIndex) return; // Prevent redundant navigation
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => HomeScreen(shelterId: shelterId),
                transitionDuration: Duration.zero, // Remove animation
              ),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => ViewPetsScreen(shelterId: shelterId), // Replace with PetsScreen
                transitionDuration: Duration.zero, // Remove animation
              ),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => AddPetScreen(shelterId: shelterId), // Replace with AddPetScreen
                transitionDuration: Duration.zero, // Remove animation
              ),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => const Placeholder(), // Replace with ApplicationsScreen
                transitionDuration: Duration.zero, // Remove animation
              ),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => ProfileScreen(shelterId: shelterId),
                transitionDuration: Duration.zero, // Remove animation
              ),
            );
            break;
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 35), // Increase icon size
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.pets, size: 35), // Increase icon size
          label: 'Pets',
        ),
        BottomNavigationBarItem(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 40), // Increase icon size
          ),
          label: '',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.message, size: 35), // Increase icon size
          label: 'Applications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle, size: 35), // Increase icon size
          label: 'Account',
        ),
      ],
    );
  }
}
