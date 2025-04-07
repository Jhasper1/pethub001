import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bottom_nav_bar.dart'; // Import BottomNavBar
import 'edit_profile_screen.dart'; // Import EditProfileScreen
import '../splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int shelterId;
  const ProfileScreen({super.key, required this.shelterId});

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
  final url = 'http://127.0.0.1:5566/shelter/${widget.shelterId}';
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final info = data['data']['info'];
      final media = data['data']['media'];

      setState(() {
        shelterInfo = {
          ...?info,
          ...?media,
        };

        if (shelterInfo!['shelter_profile'] != null) {
          shelterInfo!['shelter_profile'] =
              base64Decode(shelterInfo!['shelter_profile']);
        }

        if (shelterInfo!['shelter_cover'] != null) {
          shelterInfo!['shelter_cover'] =
              base64Decode(shelterInfo!['shelter_cover']);
        }

        isLoading = false;
      });
    } else {
      throw Exception('Failed to load shelter details');
    }
  } catch (e) {
    print("Error fetching shelter details: $e");
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
  return Scaffold(
    body: const Center(child: CircularProgressIndicator()),
    bottomNavigationBar: BottomNavBar(
      shelterId: widget.shelterId,
      currentIndex: 4,
    ),
  );
}


    if (shelterInfo == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load shelter information')),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 231, 211),
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
                          image: DecorationImage(
                              image: MemoryImage(shelterInfo!['shelter_cover']),
                              fit: BoxFit.cover),
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
                            : const AssetImage('assets/images/logo.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shelterInfo!['shelter_name'] ?? 'Unknown Shelter',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _infoRow(Icons.location_on,
                          shelterInfo!['shelter_address'] ?? 'No information'),
                      _infoRow(Icons.location_city,
                          shelterInfo!['shelter_landmark'] ?? 'No information'),
                      _infoRow(
                          Icons.phone,
                          shelterInfo!['shelter_contact']?.toString() ??
                              'No information'),
                      _infoRow(Icons.email,
                          shelterInfo!['shelter_email'] ?? 'No information'),
                      _infoRow(Icons.language,
                          shelterInfo!['shelter_social'] ?? 'No information'),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: double.infinity, // Stretch the card to the full width
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shelterInfo!['shelter_description']?.isNotEmpty == true
                            ? shelterInfo!['shelter_description']
                            : 'No Description', // Display "No Description" if empty or null
                        style: const TextStyle(fontSize: 12),
                        textAlign:
                            TextAlign.justify, // Ensure text flows continuously
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
                      builder: (_) =>
                          EditProfileScreen(shelterId: widget.shelterId),
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
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        // title: const Text('Logout Confirmation'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // close dialog
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // close dialog
                              // Navigate back to splash or login screen
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SplashScreen()),
                                (Route<dynamic> route) => false,
                              );
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
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
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
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
          Text(displayText!,
              style: const TextStyle(fontSize: 12)), // Set font size to 10
        ],
      ),
    );
  }
}
