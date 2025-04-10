import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pet_clicked.dart';

void main() {
  runApp(PetApp());
}

class PetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PetsScreen(),
    );
  }
}

class PetsScreen extends StatefulWidget {
  @override
  _PetsScreenState createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  String selectedCategory = 'All';
  List<dynamic> pets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPets();
  }

  Future<void> fetchPets() async {
    setState(() => isLoading = true);
    final url = Uri.parse("http://127.0.0.1:5566/users/petinfo");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> allPets = json.decode(response.body);
        setState(() {
          pets = selectedCategory == "All"
              ? allPets
              : allPets.where((pet) {
            final type = pet["pet_type"]?.toString().toLowerCase();
            return type == selectedCategory.toLowerCase();
          }).toList();
          isLoading = false;
        });
      } else {
        print("Failed to load pets. Status: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching pets: $e");
      setState(() => isLoading = false);
    }
  }

  Widget buildCategoryButton(String label, String type, IconData icon) {
    bool isSelected = selectedCategory == type;
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            selectedCategory = type;
          });
          fetchPets();
        },
        icon: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        label: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.orange : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black12),
          ),
        ),
      ),
    );
  }

  Widget _buildBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
        ),
      );
    }

    try {
      // Remove potential data:image/*;base64, prefix if present
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;

      return Image.memory(
        base64Decode(cleanBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.grey[600]),
            ),
          );
        },
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F1FF),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("Pet Library", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Toggle Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                buildCategoryButton("All", "All", Icons.pets),
                SizedBox(width: 10),
                buildCategoryButton("Dogs", "Dog", Icons.pets),
                SizedBox(width: 10),
                buildCategoryButton("Cats", "Cat", Icons.pets),
              ],
            ),
          ),

          // Pet Cards Grid
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : pets.isEmpty
                ? Center(child: Text("No pets found."))
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: pets.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailsScreen(petId: pet["pet_id"]),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Pet Image from base64
                            Positioned.fill(
                              child: _buildBase64Image(pet["pet_image1"]),
                            ),
                            // Pet Name Overlay
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  pet["pet_name"] ?? "Unknown",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
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
          ),
        ],
      ),
    );
  }
}