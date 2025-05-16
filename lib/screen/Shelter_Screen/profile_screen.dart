import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_screen.dart';
import 'shelter_donations_screen.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = 'http://127.0.0.1:5566/api/shelter/${widget.shelterId}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Stack(
              children: [
                Container(
                  height: 160, // Slightly taller cover image
                  decoration: shelterInfo!['shelter_cover'] != null
                      ? BoxDecoration(
                          image: DecorationImage(
                            image: MemoryImage(shelterInfo!['shelter_cover']),
                            fit: BoxFit.cover,
                          ),
                        )
                      : BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade700,
                              Colors.blue.shade400
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5), // adjust padding as needed
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(
                                0.3), // light transparent background
                          ),
                          child: const Icon(Icons.settings,
                              size: 30, color: Colors.white),
                        ),
                        onSelected: (value) async {
                          if (value == 'donation') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShelterDonationsScreen(
                                    shelterId: widget.shelterId),
                              ),
                            );
                            if (result == true) {
                              fetchShelterInfo();
                            }
                          } else if (value == 'edit') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                    shelterId: widget.shelterId),
                              ),
                            );
                            if (result == true) {
                              fetchShelterInfo();
                            }
                          } else if (value == 'change_password') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShelterChangePasswordScreen(
                                    shelterId: widget.shelterId),
                              ),
                            );
                            if (result == true) {
                              fetchShelterInfo();
                            }
                          } else if (value == 'logout') {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  content: const Text(
                                      'Are you sure you want to logout?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel',
                                          style: TextStyle(color: Colors.blue)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SplashScreen()),
                                          (Route<dynamic> route) => false,
                                        );
                                      },
                                      child: const Text('Logout',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: const [
                                Icon(Icons.edit, color: Colors.black),
                                SizedBox(width: 10),
                                Text('Edit Profile'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'donation',
                            child: Row(
                              children: const [
                                Icon(Icons.volunteer_activism,
                                    color: Colors.black),
                                SizedBox(width: 10),
                                Text('Edit Donation Info'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'change_password',
                            child: Row(
                              children: const [
                                Icon(Icons.password, color: Colors.black),
                                SizedBox(width: 10),
                                Text('Change Password'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: const [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Logout',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage:
                              shelterInfo!['shelter_profile'] != null
                                  ? MemoryImage(shelterInfo!['shelter_profile'])
                                  : const AssetImage('assets/images/logo.png')
                                      as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shelterInfo!['shelter_name'] ?? 'Unknown Shelter',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Shelter Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                      const Divider(height: 20, thickness: 0.5),
                      _infoRow(Icons.person,
                          shelterInfo!['shelter_owner'] ?? 'No information'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

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
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
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
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        // textAlign: TextAlign.justify,
                      ),
                    ],
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
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
