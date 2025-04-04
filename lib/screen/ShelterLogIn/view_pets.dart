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
  int selectedCategory = 1; // Default: Cats
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.pets, 'label': 'Dogs'},
    {'icon': Icons.pets, 'label': 'Cats'}
  ];

  List<Map<String, dynamic>> pets = [];

  Future<void> fetchPets() async {
    final url = 'http://127.0.0.1:5566/shelter/${widget.shelterId}/pets';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging

        final petInfoList =
            data['data']['pets'] as List; // Adjust this to 'pets'

        setState(() {
          pets = petInfoList.map((pet) {
            return {
              'pet_id': pet['pet_id'],
              'pet_name': pet['pet_name'],
              'pet_image1': pet['pet_image1'] != null &&
                      pet['pet_image1'].isNotEmpty
                  ? _decodeBase64Image(pet['pet_image1']
                      [0]) // Decode the first image (or handle multiple images)
                  : null,
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load pet data');
      }
    } catch (e) {
      print("Error fetching pet data: $e");
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(categories.length, (index) {
                  bool isSelected = index == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Row(
                        children: [
                          Icon(categories[index]['icon'], size: 18),
                          const SizedBox(width: 5),
                          Text(categories[index]['label']),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = index;
                        });
                      },
                      selectedColor: Colors.orange,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: pets.isEmpty
                  ? const Center(child: CircularProgressIndicator())
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
          builder: (context) => PetDetailsScreen(petId: pet['pet_id']),
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
