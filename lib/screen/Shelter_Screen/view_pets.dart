import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_bar.dart'; // Adjust the import according to your project
import 'pet_info_screen.dart'; // Adjust the import according to your project
import 'archived_pets_screen.dart'; // Adjust the import according to your project

class ViewPetsScreen extends StatefulWidget {
  final int shelterId;

  const ViewPetsScreen({super.key, required this.shelterId});

  @override
  _ViewPetsScreenState createState() => _ViewPetsScreenState();
}

class _ViewPetsScreenState extends State<ViewPetsScreen> {
  bool isLoading = true; // Add this at the top of your state class

  List<Map<String, dynamic>> pets = [];
  TextEditingController searchController = TextEditingController();
  String selectedSex = 'All';
  String selectedPetType = 'All';

  Future<void> fetchPets() async {
    final searchQuery = searchController.text;
    final sexFilter = selectedSex == 'All' ? '' : selectedSex;
    final typeFilter = selectedPetType == 'All' ? '' : selectedPetType;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/filter/${widget.shelterId}/pets/search?pet_name=$searchQuery&sex=$sexFilter&type=$typeFilter';
    try {
      final response = await http.get(Uri.parse(url),
     headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    try {
      // Remove data:image/png;base64, or similar prefixes
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
      // backgroundColor: const Color(0xFFE2F3FD),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          "Pet Library",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ArchivedPetsScreen(shelterId: widget.shelterId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                SizedBox(
                  height: 35, // smaller height for TextField
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      fetchPets(); // Re-fetch when typing
                    },
                    decoration: InputDecoration(
                      hintText: 'Search pet name...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // slightly reduced space
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
                                style: TextStyle(fontSize: 12)),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSex = value!;
                            });
                            fetchPets();
                          },
                          decoration:InputDecoration(
                            labelText: 'Sex',
                            labelStyle: GoogleFonts.poppins(fontSize: 12),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
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
                                style: TextStyle(fontSize: 12)),
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
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : pets.isEmpty
                  ? Center(child: Text("No Pets Found",
                style: GoogleFonts.poppins(),))
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
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 1,
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () async {
        // Navigate to the pet details screen and pass the pet_id
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailsScreen(
              petId: pet['pet_id'],
              shelterId: widget.shelterId,
            ),
          ),
        );

        if (result == true) {
          // Reload the list after pet is archived or updated
          fetchPets(); // Replace this with your actual method to refresh the list
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
                        color: Colors.black
                            .withOpacity(0.4), // adjust opacity here
                      ),
                    ],
                  ),
                )
              ],
            ),
            // Pet name at bottom-left
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
            // Star icon at top-right
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
