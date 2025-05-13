import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/pet_clicked.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewAllPetsScreen extends StatefulWidget {
  final int adopterId;

  const ViewAllPetsScreen({super.key, required this.adopterId});

  @override
  _ViewAllPetsScreenState createState() => _ViewAllPetsScreenState();
}

class _ViewAllPetsScreenState extends State<ViewAllPetsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> pets = [];
  TextEditingController searchController = TextEditingController();
  String selectedSex = 'All';
  String selectedPetType = 'All';
  bool priorityStatus = true; // Default to true

  Future<void> fetchPets() async {
    final searchQuery = searchController.text;
    final priorityFilter = priorityStatus
        .toString(); // Ensure it sends as 'true' or 'false' string
    final sexFilter = selectedSex == 'All' ? '' : selectedSex;
    final typeFilter = selectedPetType == 'All' ? '' : selectedPetType;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/users/pets/search/all?pet_name=$searchQuery&priority_status=$priorityFilter&sex=$sexFilter&type=$typeFilter';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if 'data' and 'data['pets']' are not null or empty
        if (data != null &&
            data['data'] != null &&
            data['data']['pets'] != null) {
          final petInfoList = data['data']['pets'] as List;

          final updatedPets = petInfoList.map((pet) {
            return {
              'pet_id': pet['pet_id'],
              'pet_name': pet['pet_name'],
              'priority_status': pet['priority_status'],
              'pet_image1':
                  pet['pet_image1'] != null && pet['pet_image1'].isNotEmpty
                      ? _decodeBase64Image(pet['pet_image1'][0])
                      : null,
            };
          }).toList();

          setState(() {
            pets = updatedPets;
            isLoading = false;
          });
        } else {
          // If the pets data is empty or null
          setState(() {
            pets = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load pet data');
      }
    } catch (e) {
      print("Error fetching pet data: $e");
      setState(() {
        pets = []; // Make sure this is cleared on error
        isLoading = false;
      });
    }
  }

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
      base64String = base64String.replaceAll(regex, '');
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding Base64 image: $e");
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- TOP FILTERS ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Title
                Row(
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
                          'Pet Library',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlue),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search Bar
                SizedBox(
                  height: 35,
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      fetchPets();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search pet name...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filters Row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: DropdownButtonFormField<String>(
                          value: selectedSex,
                          items: ['All', 'Male', 'Female']
                              .map((sex) => DropdownMenuItem(
                                    value: sex,
                                    child: Text(sex,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSex = value!;
                            });
                            fetchPets();
                          },
                          decoration: InputDecoration(
                            labelText: 'Sex',
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: DropdownButtonFormField<String>(
                          value: selectedPetType,
                          items: ['All', 'Dog', 'Cat']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPetType = value!;
                            });
                            fetchPets();
                          },
                          decoration: InputDecoration(
                            labelText: 'Pet Type',
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Priority Toggle
                    Row(
                      children: [
                        const Text("Priority"),
                        Switch(
                          value: priorityStatus,
                          onChanged: (bool value) {
                            setState(() {
                              priorityStatus = value;
                            });
                            fetchPets();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // --- PET GRID LIST ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : pets.isEmpty
                      ? Center(
                          child: Text(
                          "No Pets Found",
                          style: GoogleFonts.poppins(),
                        ))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: pets.length,
                          itemBuilder: (context, index) {
                            return _buildPetCard(pets[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserPetDetailsScreen(
              petId: pet['pet_id'],
              adopterId: widget.adopterId,
              shelterId: pet['shelter_id'],
            ),
          ),
        );
        if (result == true) {
          fetchPets();
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      pet['pet_image1'] != null
                          ? Image.memory(
                              pet['pet_image1'],
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                      Container(
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ],
                  ),
                )
              ],
            ),
            // Pet name
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  pet['pet_name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // Star icon
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                pet['priority_status'] == true ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
