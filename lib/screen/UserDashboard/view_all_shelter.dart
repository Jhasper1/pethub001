import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'shelter_clicked.dart';

class ShelterScreen extends StatefulWidget {
  final int adopterId;
  const ShelterScreen({super.key, required this.adopterId});

  @override
  State<ShelterScreen> createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  List<dynamic> shelters = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchShelters();
  }

  Future<void> fetchShelters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final response = await http.get(
          Uri.parse('http://127.0.0.1:5566/api/get/all/shelters'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          shelters = data['data']['shelters'];
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'No shelters found';
          isLoading = false;
        });
      } else if (response.statusCode == 500) {
        setState(() {
          errorMessage = 'Database error';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load shelters';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        title: Text('Shelters',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      backgroundColor: const Color.fromARGB(255, 239, 250, 255),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : shelters.isEmpty
                  ? const Center(child: Text('No shelters available'))
                  : ListView.builder(
                      itemCount: shelters.length,
                      itemBuilder: (context, index) {
                        final shelter = shelters[index];
                        final shelterId = shelter['shelter_id'];
                        final shelterInfo = shelter['shelterinfo'];
                        final shelterMedia = shelterInfo?['sheltermedia'] ?? {};
                        final shelterName =
                            shelterInfo?['shelter_name'] ?? 'No name provided';
                        final shelterProfile =
                            shelterMedia['shelter_profile'] ?? '';
                        final shelterDescription =
                            shelterInfo?['shelter_address'] ??
                                'No address available';

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
                                  // Profile Image (Circle)
                                  _buildBase64Image(shelterProfile),
                                  const SizedBox(width: 16),
                                  // Shelter Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                    ),
    );
  }
}
