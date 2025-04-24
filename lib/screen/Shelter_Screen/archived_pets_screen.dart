import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'bottom_nav_bar.dart'; // Adjust the import according to your project
import 'archived_pet_info_screen.dart'; // Adjust the import according to your project

class ArchivedPetsScreen extends StatefulWidget {
  final int shelterId;

  const ArchivedPetsScreen({super.key, required this.shelterId});

  @override
  _ArchivedPetsScreenState createState() => _ArchivedPetsScreenState();
}

class _ArchivedPetsScreenState extends State<ArchivedPetsScreen> {
  bool isLoading = true; // Add this at the top of your state class
  int selectedCategory = 1; // Default: Cats
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.pets, 'label': 'Dogs'},
    {'icon': Icons.pets, 'label': 'Cats'}
  ];

  List<Map<String, dynamic>> pets = [];
  TextEditingController searchController = TextEditingController();
  String selectedSex = 'All';
  String selectedPetType = 'All';

  Future<void> fetchPets() async {
      final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final searchQuery = searchController.text;
    final sexFilter = selectedSex == 'All' ? '' : selectedSex;
    final typeFilter = selectedPetType == 'All' ? '' : selectedPetType;

    final url =
        'http://127.0.0.1:5566/api/shelter/archive/pets/${widget.shelterId}/search?pet_name=$searchQuery&sex=$sexFilter&type=$typeFilter';
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
      // backgroundColor: const Color.fromARGB(255, 253, 226, 226),
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text(
          "Archived Pets",
          // style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 40, // smaller height for TextField
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      fetchPets(); // Re-fetch when typing
                    },
                    decoration: InputDecoration(
                      hintText: 'Search pet name...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // slightly reduced space
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
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
                          decoration: const InputDecoration(
                            labelText: 'Sex',
                            labelStyle: TextStyle(fontSize: 12),
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
                        height: 40,
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
                          decoration: const InputDecoration(
                            labelText: 'Pet Type',
                            labelStyle: TextStyle(fontSize: 12),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
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
                      ? const Center(child: Text("No Pets Found"))
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
      // bottomNavigationBar: BottomNavBar(
      //   shelterId: widget.shelterId,
      //   currentIndex: 1,
      // ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArchivedPetInfoScreen(
              petId: pet['pet_id'],
              shelterId: widget.shelterId,
            ),
          ),
        );

        // If result is true (means something was archived), refresh
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
                  child: pet['pet_image1'] != null
                      ? Image.memory(
                          pet['pet_image1'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/logo.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  pet['pet_name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}