import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_bottom_nav_bar.dart';
import 'user_edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int adopterId;
  const UserProfileScreen({Key? key, required this.adopterId}) : super(key: key);

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
    final String apiUrl = 'http://127.0.0.1:5566/user/${widget.adopterId}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        if (data != null && data is Map<String, dynamic>) {
          setState(() {
            adopterInfo = {
              ...?data['info'],
              ...?data['media'],
            };

            // Decode base64 images safely
            if (adopterInfo!['adopter_profile'] is String) {
              adopterInfo!['adopter_profile'] = base64Decode(adopterInfo!['adopter_profile']);
            }
            if (adopterInfo!['adopter_cover'] is String) {
              adopterInfo!['adopter_cover'] = base64Decode(adopterInfo!['adopter_cover']);
            }

            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load adopter details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching adopter details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (adopterInfo == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load adopter information')),
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
                            : const AssetImage('assets/images/logo.png') as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${adopterInfo!['first_name'] ?? ''} ${adopterInfo!['last_name'] ?? ''}',
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
                      _infoRow(Icons.home, adopterInfo!['address'] ?? 'No information'),
                      _infoRow(Icons.phone, adopterInfo!['contact_number']?.toString() ?? 'No information'),
                      _infoRow(Icons.email, adopterInfo!['email'] ?? 'No information'),
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
                  width: double.infinity,
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
                        adopterInfo!['adopter_description']?.isNotEmpty == true
                            ? adopterInfo!['adopter_description']
                            : 'No Description',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.justify,
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
                      builder: (_) => UserEditProfileScreen(adopterId: widget.adopterId),
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
      bottomNavigationBar: UserBottomNavBar(
        adopterId: widget.adopterId,
        currentIndex: 4,
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final displayText = text.isNotEmpty ? text : 'No information';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
