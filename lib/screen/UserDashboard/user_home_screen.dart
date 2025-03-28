import 'package:flutter/material.dart';
import '../UserLogin/user_bottom_nav_bar.dart';// Import the updated BottomNavigationBar widget
import 'package:march24/screen/UserDashboard/view_all_pets.dart';
import 'package:march24/screen/UserDashboard/view_all_shelter.dart';

class UserHomeScreen extends StatelessWidget {
  final int adopterId;

  const UserHomeScreen({Key? key, required this.adopterId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text('PetHub', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),

      bottomNavigationBar: UserBottomNavBar(
        adopterId: adopterId,
        currentIndex: 0, // Set the active tab to "Home"
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            _buildSectionTitle(context, 'Pets', PetApp()),
            _buildPetsList(context),
            _buildSectionTitle(context, 'Pet Shelters', ShelterScreen()),
            _buildSheltersList()
          ],

        ),

      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Just About to Adopt?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('See how you can find friends who are a match for you'),
              ],
            ),
          ),
          Text(
            'Welcome, Adopter ID: $adopterId',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/images/adopter.png'), // Ensure this image exists
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Widget page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
            child: Text("View All"),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildPetCard(context, "Mochi", "Abyssinian", "assets/images/logo.png"),
          _buildPetCard(context, "Luna", "Chihuahua", "assets/images/logo.png"),
          _buildPetCard(context, "Casper", "Maine Coon", "assets/images/logo.png"),
        ],
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, String name, String breed, String image) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Clicked on $name")),
        );
      },
      child: Container(
        width: 120,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(image, height: 80, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(breed, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheltersList() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildShelterCard("Happy Paws Shelter", "Downtown City", "assets/images/logo.png"),
          _buildShelterCard("Furry Friends Haven", "Uptown Area", "assets/images/logo.png"),
        ],
      ),
    );
  }

  Widget _buildShelterCard(String name, String location, String image) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(image, width: 50, height: 50, fit: BoxFit.cover),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(location),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
