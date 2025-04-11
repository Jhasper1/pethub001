import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/shelter_clicked.dart';
import '../UserLogin/user_bottom_nav_bar.dart';
import 'package:march24/screen/UserDashboard/view_all_pets.dart';
import 'package:march24/screen/UserDashboard/view_all_shelter.dart';
import 'package:march24/screen/UserDashboard/pet_clicked.dart';
import 'package:march24/screen/ShelterLogIn/shelter_notification.dart';

class UserHomeScreen extends StatefulWidget {
  final int adopterId;

  const UserHomeScreen({Key? key, required this.adopterId}) : super(key: key);

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
    const String petApiUrl = 'http://127.0.0.1:5566/users/petinfo';
    const String shelterApiUrl = 'http://127.0.0.1:5566/allshelter';

    try {
      final petResponse = await http.get(Uri.parse(petApiUrl));
      final shelterResponse = await http.get(Uri.parse(shelterApiUrl));

      if (petResponse.statusCode == 200 && shelterResponse.statusCode == 200) {
        final petData = jsonDecode(petResponse.body);
        final shelterData = jsonDecode(shelterResponse.body);

        setState(() {
          pets = List<Map<String, dynamic>>.from(petData).take(3).toList();
          shelters = List<Map<String, dynamic>>.from(shelterData).take(3).toList();
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : RefreshIndicator(
        onRefresh: fetchPetsAndShelters,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 20),
              _buildSectionTitle('Featured Pets', PetApp()),
              _buildFeaturedPetsList(),
              const SizedBox(height: 20),
              _buildSectionTitle('Shelters', ShelterScreen()),
              _buildSheltersList(),
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
      height: 230,
      child: pets.isEmpty
          ? const Center(child: Text("No pets available"))
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          String image = pet['pet_image1'] ?? '';
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PetDetailsScreen(petId: pet["pet_id"]),
              ),
            ),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: image.isNotEmpty
                        ? Image.memory(
                      base64Decode(image),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 140,
                      color: Colors.blue.shade50,
                      child: const Icon(Icons.pets, size: 40),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet['pet_name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(pet['pet_type'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
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
              builder: (_) =>
                  ShelterDetailsPage(shelterId: shelter["shelter_id"]),
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
                    child: const Icon(Icons.home_work, color: Colors.blue),
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
