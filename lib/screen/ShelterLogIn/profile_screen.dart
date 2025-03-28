import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bottom_nav_bar.dart'; // Import BottomNavBar

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
    final String apiUrl = 'http://127.0.0.1:5566/shelter/getinfo/${widget.shelterId}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          shelterInfo = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load shelter info');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching shelter info: $e');
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
                  color: Colors.grey[300],
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(Icons.edit, color: Colors.black),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const SizedBox(height: 90),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: const AssetImage('assets/images/logo.png'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shelterInfo!['shelter_name'] ?? 'Unknown Shelter', // Add default value
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _infoRow(Icons.location_on, shelterInfo!['shelter_address'] ?? 'Not available'),
                      _infoRow(Icons.location_city, shelterInfo!['shelter_landmark'] ?? 'Not available'),
                      _infoRow(Icons.phone, shelterInfo!['shelter_contact'] ?? 'Not available'),
                      _infoRow(Icons.email, shelterInfo!['shelter_email'] ?? 'Not available'),
                      _infoRow(Icons.language, shelterInfo!['social_media'] ?? 'Not available'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Description Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 80,
                    child: Text(
                      shelterInfo!['shelter_description']?.isNotEmpty == true
                          ? shelterInfo!['shelter_description']
                          : 'No Description', // Display "No Description" if empty or null
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                      style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
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
    final displayText = text?.isNotEmpty == true ? text : 'Not available';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 10),
          Text(displayText!, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
