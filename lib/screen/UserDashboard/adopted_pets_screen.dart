import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserLogin/user_bottom_nav_bar.dart'; // Import the UserBottomNavbar correctly

class AdoptedPet {
  final String petName;
  final String petType;
  final int petAge;
  final String ageType;
  final String petDescription; // Optional: Add description if needed
  final String petImage1;

  AdoptedPet({
    required this.petName,
    required this.petType,
    required this.petAge,
    required this.ageType,
    required this.petDescription,
    required this.petImage1,
  });

  // Factory constructor to create AdoptedPet from JSON
  factory AdoptedPet.fromJson(Map<String, dynamic> json) {
    return AdoptedPet(
      petName: json['pet_name'] ?? 'Unknown',
      petType: json['pet_type'] ?? 'Unknown',
      petAge: json['pet_age'] ?? 0,
      ageType: json['age_type'] ?? 'Unknown',
      petDescription: json['pet_descriptions'] ?? 'No description available',
      petImage1: json['pet_image1'] ?? '', // Base64 string
    );
  }
}

// Function to fetch adopted pets by adopter_id
Future<List<AdoptedPet>> fetchAdoptedPets(int adopterId) async {
  final response = await http.get(
    Uri.parse('http://127.0.0.1:5566/adopter/$adopterId/adopt'), // Replace with your actual API endpoint
  );

  if (response.statusCode == 200) {
    // Parse the JSON response
    List<dynamic> jsonData = json.decode(response.body)['data']; // Ensure data exists
    return jsonData.map((pet) => AdoptedPet.fromJson(pet)).toList();
  } else {
    throw Exception('Failed to load adopted pets');
  }
}

// Adopted Pets Screen to display the list of adopted pets
class AdoptedPetsScreen extends StatefulWidget {
  final int adopterId;

  AdoptedPetsScreen({required this.adopterId});

  @override
  _AdoptedPetsScreenState createState() => _AdoptedPetsScreenState();
}

class _AdoptedPetsScreenState extends State<AdoptedPetsScreen> {
  late Future<List<AdoptedPet>> adoptedPets;

  @override
  void initState() {
    super.initState();
    adoptedPets = fetchAdoptedPets(widget.adopterId); // Fetch pets for the given adopter ID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adopted Pets'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      bottomNavigationBar: UserBottomNavBar(
        adopterId: widget.adopterId,
        currentIndex: 1,
      ),
      body: FutureBuilder<List<AdoptedPet>>(
        future: adoptedPets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No adopted pets found.'));
          } else {
            final pets = snapshot.data!;
            return ListView.builder(
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];

                // Decode the base64 image if available
                Uint8List? decodedImage = pet.petImage1.isNotEmpty
                    ? base64Decode(pet.petImage1) // Decode base64 string to Uint8List
                    : null;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(pet.petName),
                    subtitle: Text('Age: ${pet.petAge}, ${pet.ageType} ,Type: ${pet.petType}'),
                    leading: decodedImage != null
                        ? Image.memory(decodedImage, width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.pets),
                    onTap: () {
                      // Optional: You can add functionality to navigate to a pet's details screen here
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adopted Pets App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AdoptedPetsScreen(adopterId: 1), // Replace with dynamic adopterId as needed
    );
  }
}
