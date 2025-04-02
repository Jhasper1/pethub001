import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bottom_nav_bar.dart'; // Import BottomNavBar
import 'edit_profile_screen.dart'; // Import EditProfileScreen

class ProfileScreen extends StatefulWidget {
  final int shelterId;
  const ProfileScreen({Key? key, required this.shelterId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? shelterInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchShelterInfo();
  }

  Future<void> fetchShelterInfo() async {
    final String apiUrl = 'http://127.0.0.1:5566/shelter/${widget.shelterId}';
    const String baseImageUrl = 'http://127.0.0.1:5566/images/shelter_media/';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        if (data != null && data is Map) {
          setState(() {
            shelterInfo = {
              ...?data['info'],  // Safely extract shelter info
              ...?data['media'], // Safely extract shelter media
            };

            // Prepend the base URL to shelter_profile and shelter_cover
            if (shelterInfo!['shelter_profile'] != null) {
  shelterInfo!['shelter_profile'] = base64Decode(shelterInfo!['shelter_profile']);
}

if (shelterInfo!['shelter_cover'] != null) {
  shelterInfo!['shelter_cover'] = base64Decode(shelterInfo!['shelter_cover']);
}


            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load shelter details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching shelter details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (shelterInfo == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load shelter information')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: shelterInfo!['shelter_cover'] != null
    ? BoxDecoration(
        image: DecorationImage(image: MemoryImage(shelterInfo!['shelter_cover']), fit: BoxFit.cover),
      )
    : const BoxDecoration(color: Colors.orange),

                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const SizedBox(height: 90),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: shelterInfo!['shelter_profile'] != null
    ? MemoryImage(shelterInfo!['shelter_profile'])
    : const AssetImage('assets/images/logo.png') as ImageProvider,

                      ),
                      const SizedBox(height: 10),
                      Text(
                        shelterInfo!['shelter_name'] ?? 'Unknown Shelter',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _infoRow(Icons.location_on, shelterInfo!['shelter_address'] ?? 'No information'),
                      _infoRow(Icons.location_city, shelterInfo!['shelter_landmark'] ?? 'No information'),
                      _infoRow(Icons.phone, shelterInfo!['shelter_contact']?.toString() ?? 'No information'),
                      _infoRow(Icons.email, shelterInfo!['shelter_email'] ?? 'No information'),
                      _infoRow(Icons.language, shelterInfo!['shelter_social'] ?? 'No information'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Description Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: double.infinity, // Stretch the card to the full width
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shelterInfo!['shelter_description']?.isNotEmpty == true
                            ? shelterInfo!['shelter_description']
                            : 'No Description', // Display "No Description" if empty or null
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.justify, // Ensure text flows continuously
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Edit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  // Navigate to EditProfileScreen and wait for the result
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(shelterId: widget.shelterId),
                    ),
                  );

                  // Refresh the profile screen if changes were saved
                  if (result == true) {
                    fetchShelterInfo();
                  }
                },
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: GestureDetector(
                onTap: () {
                  // Handle logout action
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Logout',
                      style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 4, // Set the active tab to "Account"
      ),
    );
  }

  Widget _infoRow(IconData icon, String? text) {
    // Provide a default value if text is null or empty
    final displayText = text?.isNotEmpty == true ? text : 'No information';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 10),
          Text(displayText!, style: const TextStyle(fontSize: 12)), // Set font size to 10
        ],
      ),
    );
  }
}
