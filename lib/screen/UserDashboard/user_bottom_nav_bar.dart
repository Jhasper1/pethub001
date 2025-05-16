import 'package:flutter/material.dart';
import 'adopted_pet_list_screen.dart';
import 'user_profile_screen.dart';
import 'user_home_screen.dart';
import 'adopted_pets_screen.dart';

class UserBottomNavBar extends StatelessWidget {
  final int adopterId; // Default value for applicationId
  final int currentIndex;
  final int applicationId; // Optional applicationId

  const UserBottomNavBar({
    super.key,
    required this.adopterId,
    required this.currentIndex,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    UserHomeScreen(adopterId: adopterId),
                transitionDuration: Duration.zero,
              ),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    AdoptedPetListScreen(
                  adopterId: adopterId,
                  applicationId:
                      applicationId, 
                ),
                transitionDuration: Duration.zero,
              ),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                    UserProfileScreen(adopterId: adopterId),
                transitionDuration: Duration.zero,
              ),
            );
            break;
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 35),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.pets, size: 35),
          label: 'My Adoptions', // Changed label to be more specific
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle, size: 35),
          label: 'Account',
        ),
      ],
    );
  }
}
