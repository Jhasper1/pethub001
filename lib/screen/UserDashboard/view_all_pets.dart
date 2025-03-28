import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pet_clicked.dart'; // Import the pet details screen

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
  String selectedCategory = 'All'; // Default category
  List pets = [];

  @override
  void initState() {
    super.initState();
    fetchPets();
  }

  Future<void> fetchPets() async {
    final url = Uri.parse("http://127.0.0.1:5566/users/petinfo"); // Replace with actual API URL

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List allPets = json.decode(response.body);
        setState(() {
          pets = selectedCategory == "All"
              ? allPets
              : allPets.where((pet) =>
          pet["pet_type"]?.toLowerCase() == selectedCategory.toLowerCase()).toList();
        });
      } else {
        print("Failed to load pets. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching pets: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pets"), centerTitle: true),
      body: Column(
        children: [
          // Category Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                categoryButton("All", "All"),
                SizedBox(width: 10),
                categoryButton("Dogs", "Dog"),
                SizedBox(width: 10),
                categoryButton("Cats", "Cat"),
              ],
            ),
          ),

          // Pet List
          Expanded(
            child: pets.isEmpty
                ? Center(child: Text("No pets found in this category"))
                : ListView.builder(
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return ListTile(
                  title: Text(pet["pet_name"], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Age: ${pet["pet_age"]}  |  Sex: ${pet["pet_sex"]}"),
                  leading: Icon(Icons.pets, color: Colors.orange),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to PetDetailsScreen with pet_id only
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailsScreen(petId: pet["pet_id"]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryButton(String label, String type) {
    bool isSelected = selectedCategory == type;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          selectedCategory = type;
        });
        fetchPets();
      },
      icon: Icon(Icons.pets, color: isSelected ? Colors.white : Colors.black),
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
