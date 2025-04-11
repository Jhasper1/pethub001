import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart'; // Import the updated BottomNavigationBar widget

class HomeScreen extends StatelessWidget {
  final int shelterId;

  const HomeScreen({super.key, required this.shelterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        shelterId: shelterId,
        currentIndex: 0, // Set the active tab to "Home"
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'PetHub',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, Shelter ID: $shelterId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
              children: [
                Image.asset(
                'assets/images/logo.png',
                height: 40,
                ),
                const SizedBox(width: 20),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'What are you planning to do today?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  ],
                ),
                ),
              ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                List<String> categories = [
                  'Dogs', 'Cats', 'Rabbits', 'Birds', 'Reptiles', 'Fish', 'Primates', 'Other'
                ];
                return Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.pets, color: Colors.lightBlue),
                    ),
                    const SizedBox(height: 5),
                    Text(categories[index]),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Pets Near You'),
            _buildPetList(),
            _buildSectionHeader('Your Preferences'),
            _buildPetList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'View All',
              style: TextStyle(color: Colors.lightBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          List<String> petNames = ['Mochi', 'Luna', 'Casper'];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                      'assets/images/logo.png', // Replace with actual images
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  petNames[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('1.2 km - Breed', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
