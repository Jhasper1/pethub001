import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bottom_nav_bar.dart'; // Adjust the import according to your project
import 'pet_info_screen.dart'; // Adjust the import according to your project

class ViewPetsScreen extends StatefulWidget {
  final int shelterId;

  const ViewPetsScreen({super.key, required this.shelterId});

  @override
  _ViewPetsScreenState createState() => _ViewPetsScreenState();
}

class _ViewPetsScreenState extends State<ViewPetsScreen> {
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
    final searchQuery = searchController.text;
    final sexFilter = selectedSex == 'All' ? '' : selectedSex;
    final typeFilter = selectedPetType == 'All' ? '' : selectedPetType;

    final url =
        'http://127.0.0.1:5566/filter/${widget.shelterId}/pets/search?pet_name=$searchQuery&sex=$sexFilter&type=$typeFilter';
    try {
      final response = await http.get(Uri.parse(url));
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
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false, // This hides the back button
        title: const Text(
          "Pet Library",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    fetchPets(); // Re-fetch when typing
                  },
                  decoration: InputDecoration(
                    hintText: 'Search pets by name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSex,
                        items: ['All', 'Male', 'Female']
                            .map((sex) => DropdownMenuItem(
                                  value: sex,
                                  child: Text(sex),
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
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPetType,
                        items: ['All', 'Dog', 'Cat']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
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
                          border: OutlineInputBorder(),
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
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 1,
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () {
        // Navigate to the pet details screen and pass the pet_id
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailsScreen(
                petId: pet['pet_id'], shelterId: widget.shelterId),
          ),
        );
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
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
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
