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
  List<Map<String, dynamic>> adoptedPets = [];
  bool isLoading = true;

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
          adoptedPets = List<Map<String, dynamic>>.from(data['data']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopted Pets'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : adoptedPets.isEmpty
              ? const Center(child: Text('No adopted pets found'))
              : ListView.builder(
                  itemCount: adoptedPets.length,
                  itemBuilder: (context, index) {
                    final pet = adoptedPets[index];
                    final base64Image = pet['pet_image1'];
                    Widget leadingWidget;

                    if (base64Image != null && base64Image.isNotEmpty) {
                      try {
                        Uint8List imageBytes = base64Decode(base64Image);
                        leadingWidget = Image.memory(
                          imageBytes,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        );
                      } catch (e) {
                        leadingWidget = const Icon(Icons.pets, size: 50);
                      }
                    } else {
                      leadingWidget = const Icon(Icons.pets, size: 50);
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        leading: leadingWidget,
                        title: Text(pet['pet_name'] ?? 'Unknown'),
                        subtitle: Text(
                            'Shelter: ${pet['shelter_name'] ?? 'Unknown'}'),
                        onTap: () {
                          int applicationId = pet['application_id'] ?? 0;

                          if (applicationId != 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplicationDetailsScreen(
                                    adopterId: widget.adopterId,
                                    applicationId: applicationId),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Invalid application ID')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
      bottomNavigationBar: UserBottomNavBar(
        adopterId: widget.adopterId,
        currentIndex: 1,
        applicationId: widget.applicationId,
      ),
    );
  }
}
