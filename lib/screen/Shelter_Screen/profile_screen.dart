import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bottom_nav_bar.dart';
import 'edit_profile_screen.dart';
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
      backgroundColor: const Color(0xFFF5F9FF), // Light blue background
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Stack(
              children: [
                Container(
                  height: 180, // Slightly taller cover image
                  decoration: shelterInfo!['shelter_cover'] != null
                      ? BoxDecoration(
                    image: DecorationImage(
                      image: MemoryImage(shelterInfo!['shelter_cover']),
                      fit: BoxFit.cover,
                    ),
                  )
                      : BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Text(
                      'Shelter Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const SizedBox(height: 110),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: shelterInfo!['shelter_profile'] != null
                              ? MemoryImage(shelterInfo!['shelter_profile'])
                              : const AssetImage('assets/images/logo.png')
                          as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shelterInfo!['shelter_name'] ?? 'Unknown Shelter',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _infoRow(Icons.location_on,
                          shelterInfo!['shelter_address'] ?? 'No information'),
                      const Divider(height: 20, thickness: 0.5),
                      _infoRow(Icons.location_city,
                          shelterInfo!['shelter_landmark'] ?? 'No information'),
                      const Divider(height: 20, thickness: 0.5),
                      _infoRow(
                          Icons.phone,
                          shelterInfo!['shelter_contact']?.toString() ??
                              'No information'),
                      const Divider(height: 20, thickness: 0.5),
                      _infoRow(Icons.email,
                          shelterInfo!['shelter_email'] ?? 'No information'),
                      const Divider(height: 20, thickness: 0.5),
                      _infoRow(Icons.language,
                          shelterInfo!['shelter_social'] ?? 'No information'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'About Us',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        shelterInfo!['shelter_description']?.isNotEmpty == true
                            ? shelterInfo!['shelter_description']
                            : 'No description provided',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Edit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfileScreen(shelterId: widget.shelterId),
                      ),
                    );
                    if (result == true) {
                      fetchShelterInfo();
                    }
                  },
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Confirm Logout',
                              style: TextStyle(color: Colors.blue)),
                          content: const Text(
                              'Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.blue)),
                            ),
                            TextButton(
                              onPressed: () async {
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
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 4,
      ),
    );
  }

  Widget _infoRow(IconData icon, String? text) {
    final displayText = text?.isNotEmpty == true ? text : 'No information';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayText!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}