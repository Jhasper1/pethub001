import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shelter_clicked.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_bottom_nav_bar.dart';
import 'view_all_pets.dart';
import 'view_all_shelter.dart';
import 'pet_clicked.dart';
import 'adopter_notification.dart';

class UserHomeScreen extends StatefulWidget {
  final int adopterId;

  const UserHomeScreen({super.key, required this.adopterId});

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Map<String, dynamic>> pets = [];
  List<Map<String, dynamic>> shelters = [];
  bool isLoading = true;
  String errorMessage = '';
  int _unreadCount = 0; // Only this is needed

  @override
  void initState() {
    super.initState();
    fetchPetsAndShelters();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final adopterId = widget.adopterId;
    if (token == null || adopterId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5566/api/adopter/$adopterId/notifications/unread_count'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _unreadCount = data['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> fetchPetsAndShelters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    const String petApiUrl = 'http://127.0.0.1:5566/api/users/petinfo';
    const String shelterApiUrl = 'http://127.0.0.1:5566/api/get/all/shelters';

    try {
      final petResponse = await http.get(Uri.parse(petApiUrl), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      final shelterResponse =
          await http.get(Uri.parse(shelterApiUrl), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (petResponse.statusCode == 200 && shelterResponse.statusCode == 200) {
        final petData = jsonDecode(petResponse.body);
        final shelterData =
            jsonDecode(shelterResponse.body)['data']['shelters'];

        final approvedShelters = List<Map<String, dynamic>>.from(shelterData)
            .where((shelter) =>
                shelter['reg_status'] == 'approved' &&
                shelter['status'] == 'active')
            .toList();

        setState(() {
          pets = List<Map<String, dynamic>>.from(petData)
              .where((pet) => pet['priority_status'] == true)
              .take(5)
              .toList();

          shelters = approvedShelters.take(5).toList();

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load data. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Connection error. Please check your internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 250, 255),
      bottomNavigationBar: UserBottomNavBar(
        adopterId: widget.adopterId,
        currentIndex: 0,
        applicationId: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : RefreshIndicator(
                  onRefresh: fetchPetsAndShelters,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    height: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'PetHub',
                                    style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.lightBlue),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.notifications),
                                      onPressed: () {}),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildWelcomeBanner(),
                        const SizedBox(height: 10),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                    'Featured Pets',
                                    ViewAllPetsScreen(
                                      adopterId: widget.adopterId,
                                    )),
                                _buildFeaturedPetsList(),
                                const SizedBox(height: 20),
                                _buildSectionTitle(
                                    'Shelters',
                                    ShelterScreen(
                                      adopterId: widget.adopterId,
                                    )),
                                _buildSheltersList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find your perfect furry companion today',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ]),
          ),
          const Icon(Icons.pets, size: 40, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900)),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            ),
            child: Text(
              'View All',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeaturedPetsList() {
    return SizedBox(
      height: 200,
      child: pets.isEmpty
          ? const Center(child: Text("No featured pets available"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                final imageBytes = pet['pet_image1'];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserPetDetailsScreen(
                        petId: pet['pet_id'],
                        adopterId: widget.adopterId,
                        shelterId: pet['shelter_id'],
                      ),
                    ),
                  ),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      elevation: 3,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    imageBytes != null && imageBytes.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(imageBytes),
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/logo.png',
                                            fit: BoxFit.cover,
                                          ),
                                    Container(
                                      color: Colors.black.withOpacity(0.1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.70),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                pet['pet_name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              pet['priority_status'] == true
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const CircleAvatar(
        radius: 40,
        child: Icon(Icons.pets),
      );
    }

    try {
      Uint8List bytes = base64Decode(base64String);
      return CircleAvatar(
        radius: 40,
        backgroundImage: MemoryImage(bytes),
      );
    } catch (e) {
      return const CircleAvatar(
        radius: 40,
        child: Icon(Icons.image_not_supported),
      );
    }
  }

  Widget _buildSheltersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shelters.length,
      itemBuilder: (context, index) {
        final shelter = shelters[index];
        final shelterId = shelter['shelter_id'];
        final shelterInfo = shelter['shelterinfo'];
        final shelterMedia = shelterInfo?['sheltermedia'] ?? {};
        final shelterName = shelterInfo?['shelter_name'] ?? 'No name provided';
        final shelterProfile = shelterMedia['shelter_profile'] ?? '';
        final shelterDescription =
            shelterInfo?['shelter_address'] ?? 'No address available';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShelterDetailsScreen(
                  shelterId: shelterId,
                  adopterId: widget.adopterId,
                ),
              ),
            );
          },
          child: Card(
            color: Colors.white,
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBase64Image(shelterProfile),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shelterName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shelterDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
