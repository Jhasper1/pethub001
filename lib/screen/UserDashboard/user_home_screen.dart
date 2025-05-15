import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/shelter_clicked.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_bottom_nav_bar.dart';
import 'package:march24/screen/UserDashboard/view_all_pets.dart';
import 'package:march24/screen/UserDashboard/view_all_shelter.dart';
import 'package:march24/screen/UserDashboard/pet_clicked.dart';
import 'package:march24/screen/Shelter_Screen/shelter_notification.dart';

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

  @override
  void initState() {
    super.initState();
    fetchPetsAndShelters();
  }

  Future<void> fetchPetsAndShelters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    const String petApiUrl = 'http://127.0.0.1:5566/api/users/petinfo';
    const String shelterApiUrl = 'http://127.0.0.1:5566/api/allshelter';

    try {
      final petResponse = await http.get(Uri.parse(petApiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      final shelterResponse = await http.get(Uri.parse(shelterApiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });


      print("Pet API Response: ${petResponse.body}");
      print("Shelter API Response: ${shelterResponse.body}");

      if (petResponse.statusCode == 200 && shelterResponse.statusCode == 200) {
        final petData = jsonDecode(petResponse.body);
        final shelterData = jsonDecode(shelterResponse.body)['data'];

        setState(() {
          pets = List<Map<String, dynamic>>.from(petData)
              .where((pet) => pet['priority_status'] == true)
              .take(5)
              .toList();
          shelters =
              List<Map<String, dynamic>>.from(shelterData).take(3).toList();

          print("Filtered Pets: $pets");
          print("Filtered Shelters: $shelters");

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
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'PetHub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShelterNotificationScreen()),
              );
            },
          )
        ],
      ),
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
                        _buildWelcomeBanner(),
                        const SizedBox(height: 20),
                        _buildSectionTitle(
                            'Featured Pets',
                            ViewAllPetsScreen(
                              adopterId: widget.adopterId,
                            )),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
              ],
            ),
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
                          // Pet name at bottom-left
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.70),
                                borderRadius: BorderRadius.circular(5),
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
                          // Star icon at top-right
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

  Widget _buildSheltersList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shelters.length,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final shelter = shelters[index];
        String image = shelter['shelter_profile'] ?? '';
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShelterDetailsScreen(
                shelterId: shelter["shelter_id"],
                adopterId: widget.adopterId,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image.isNotEmpty
                      ? Image.memory(
                          base64Decode(image),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.blue.shade50,
                          child:
                              const Icon(Icons.home_work, color: Colors.blue),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter['shelter_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        shelter['shelter_address'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }
}