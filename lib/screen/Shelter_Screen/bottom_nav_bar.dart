import 'package:flutter/material.dart';
import 'package:march24/screen/Shelter_Screen/home_screen.dart';
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
      selectedItemColor: Colors.lightBlue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false, // Hide labels for inactive pages
      currentIndex: currentIndex, // Set the active tab
      selectedLabelStyle: const TextStyle(fontSize: 10), // Hide selected label
      onTap: (index) {
  switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => HomeScreen(shelterId: shelterId),
          transitionDuration: Duration.zero,
        ),
      );
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => ViewPetsScreen(shelterId: shelterId),
          transitionDuration: Duration.zero,
        ),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => AddPetScreen(shelterId: shelterId),
          transitionDuration: Duration.zero,
        ),
      );
      break;
    case 3:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const Placeholder(),
          transitionDuration: Duration.zero,
        ),
      );
      break;
    case 4:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => ProfileScreen(shelterId: shelterId),
          transitionDuration: Duration.zero,
        ),
      );
      break;
  }
},

      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 30), // Increase icon size
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.pets, size: 30), // Increase icon size
          label: 'Pets',
        ),
        BottomNavigationBarItem(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 45), // Increase icon size
          ),
          label: '',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.message, size: 30), // Increase icon size
          label: 'Applications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle, size: 30), // Increase icon size
          label: 'Account',
        ),
      ],
    );
  }
}
