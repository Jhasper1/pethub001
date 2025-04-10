import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_bottom_nav_bar.dart';
import 'user_edit_profile_screen.dart';
import '../splash_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int adopterId;
  const UserProfileScreen({super.key, required this.adopterId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? adopterInfo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdopterInfo();
  }

  Future<void> fetchAdopterInfo() async {
    final url = 'http://127.0.0.1:5566/user/${widget.adopterId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging

        setState(() {
          adopterInfo = data['data']['info'] ?? {};

          // Handle media if exists
          if (data['data']['media'] != null) {
            adopterInfo!.addAll(data['data']['media']);
          }

          if (adopterInfo!['adopter_profile'] != null) {
            adopterInfo!['adopter_profile'] =
                base64Decode(adopterInfo!['adopter_profile']);
          }

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load adopter details');
      }
    } catch (e) {
      print("Error fetching adopter details: $e");
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
        bottomNavigationBar: UserBottomNavBar(
          adopterId: widget.adopterId,
          currentIndex: 4,
        ),
      );
    }

    if (adopterInfo == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load adopter information')),
      );
    }

    // Safely get the full name
    String fullName = '${adopterInfo!['first_name'] ?? ''} ${adopterInfo!['last_name'] ?? ''}'.trim();
    if (fullName.isEmpty) fullName = 'Unknown User';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 231, 211),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const SizedBox(height: 90),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: adopterInfo!['adopter_profile'] != null
                            ? MemoryImage(adopterInfo!['adopter_profile'])
                            : const AssetImage('assets/images/logo.png')
                        as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        fullName,
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
                          adopterInfo!['address'] ?? 'No information'),
                      _infoRow(
                          Icons.phone,
                          adopterInfo!['contact_number']?.toString() ??
                              'No information'),
                      _infoRow(Icons.email,
                          adopterInfo!['email'] ?? 'No information'),
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
                  width: double.infinity,
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
                        adopterInfo!['description'] ?? 'No description available',
                        style: const TextStyle(fontSize: 12),
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
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserEditProfileScreen(adopterId: widget.adopterId),
                    ),
                  );

                  if (result == true) {
                    fetchAdopterInfo();
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
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
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
      bottomNavigationBar: UserBottomNavBar(
        adopterId: widget.adopterId,
        currentIndex: 4,
      ),
    );
  }

  Widget _infoRow(IconData icon, String? text) {
    final displayText = text?.isNotEmpty == true ? text : 'No information';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 10),
          Text(displayText!,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}