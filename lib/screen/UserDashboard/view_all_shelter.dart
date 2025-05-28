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
  List<dynamic> filteredShelters = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchShelters();
    searchController.addListener(_filterShelters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          shelters = data['data']['shelters'];
          filteredShelters = shelters;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.statusCode == 404
              ? 'No shelters found'
              : response.statusCode == 500
                  ? 'Database error'
                  : 'Failed to load shelters';
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

  void _filterShelters() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredShelters = shelters.where((shelter) {
        final shelterInfo = shelter['shelterinfo'];
        final name =
            (shelterInfo?['shelter_name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
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
        title: Text(
          'Shelters',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 239, 250, 255),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search shelters...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Shelters (${filteredShelters.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filteredShelters.isEmpty
                            ? const Center(child: Text('No shelters found'))
                            : ListView.builder(
                                itemCount: filteredShelters.length,
                                itemBuilder: (context, index) {
                                  final shelter = filteredShelters[index];
                                  final shelterId = shelter['shelter_id'];
                                  final shelterInfo = shelter['shelterinfo'];
                                  final shelterMedia =
                                      shelterInfo?['sheltermedia'] ?? {};
                                  final shelterName =
                                      shelterInfo?['shelter_name'] ??
                                          'No name provided';
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
                                          builder: (context) =>
                                              ShelterDetailsScreen(
                                            shelterId: shelterId,
                                            adopterId: widget.adopterId,
                                          ),
                                        ),
                                      );
                                    },

      
                                    child: Card(
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildBase64Image(shelterProfile),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    shelterName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                      ),
                    ],
                  ),
                ),
    );
  }
}
