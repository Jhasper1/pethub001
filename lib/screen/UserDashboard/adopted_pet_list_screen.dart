import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'user_bottom_nav_bar.dart';
import 'adopted_pets_screen.dart';

class AdoptedPetListScreen extends StatefulWidget {
  final int adopterId;
  final int applicationId;

  const AdoptedPetListScreen({
    Key? key,
    required this.adopterId,
    required this.applicationId,
  }) : super(key: key);

  @override
  _AdoptedPetListScreenState createState() => _AdoptedPetListScreenState();
}

class _AdoptedPetListScreenState extends State<AdoptedPetListScreen> {
  List<Map<String, dynamic>> allAdoptedPets = [];
  List<Map<String, dynamic>> filteredPets = [];
  bool isLoading = true;
  String selectedCategory = 'inprogress';

  final Map<String, List<String>> statusCategories = {
    'inprogress': ['pending', 'interview', 'approved'],
    'completed': ['completed'],
    'rejected': ['rejected'],
  };

  @override
  void initState() {
    super.initState();
    fetchAdoptedPets();
  }

  Future<void> fetchAdoptedPets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/applications/allpets/${widget.adopterId}';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allAdoptedPets = List<Map<String, dynamic>>.from(data['data']);
          _applyFilter();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch adopted pets')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _applyFilter() {
    filteredPets = allAdoptedPets.where((pet) {
      final status = (pet['status'] ?? '').toString().toLowerCase();
      return statusCategories[selectedCategory]!.contains(status);
    }).toList();
  }

  void filterPetsByCategory(String category) {
    setState(() {
      selectedCategory = category;
      _applyFilter();
    });
  }

  String getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'interview':
        return 'Interview';
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'interview':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCategoryChip(String label, String category) {
    return GestureDetector(
      onTap: () => filterPetsByCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedCategory == category ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selectedCategory == category ? Colors.blue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedCategory == category ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopted Pets'),
      ),
      body: Column(
        children: [
          // New white category selector
          Container(
            margin: const EdgeInsets.all(16.0),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryChip('In Progress', 'inprogress'),
                _buildCategoryChip('Completed', 'completed'),
                _buildCategoryChip('Rejected', 'rejected'),
              ],
            ),
          ),
          // Pet list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPets.isEmpty
                    ? Center(
                        child: Text(
                          'No ${selectedCategory} pets found',
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPets.length,
                        itemBuilder: (context, index) {
                          final pet = filteredPets[index];
                          final base64Image = pet['pet_image1'];
                          final status = (pet['status'] ?? '').toString();

                          // Create circular avatar for pet image
                          Widget petAvatar;
                          if (base64Image != null && base64Image.isNotEmpty) {
                            try {
                              Uint8List imageBytes = base64Decode(base64Image);
                              petAvatar = CircleAvatar(
                                radius: 30,
                                backgroundImage: MemoryImage(imageBytes),
                                backgroundColor: Colors.transparent,
                              );
                            } catch (e) {
                              petAvatar = CircleAvatar(
                                radius: 30,
                                child: Icon(Icons.pets, size: 30),
                                backgroundColor: Colors.grey[200],
                              );
                            }
                          } else {
                            petAvatar = CircleAvatar(
                              radius: 30,
                              child: Icon(Icons.pets, size: 30),
                              backgroundColor: Colors.grey[200],
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Stack(
                              children: [
                                ListTile(
                                  leading: petAvatar,
                                  title: Text(pet['pet_name'] ?? 'Unknown'),
                                  subtitle: Text(
                                      'Shelter: ${pet['shelter_name'] ?? 'Unknown'}'),
                                  onTap: () {
                                    int applicationId =
                                        pet['application_id'] ?? 0;
                                    if (applicationId != 0) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ApplicationDetailsScreen(
                                                  adopterId: widget.adopterId,
                                                  applicationId: applicationId),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Invalid application ID')),
                                      );
                                    }
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      getStatusDisplayText(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: UserBottomNavBar(
        adopterId: widget.adopterId,
        currentIndex: 1,
        applicationId: widget.applicationId,
      ),
    );
  }
}
