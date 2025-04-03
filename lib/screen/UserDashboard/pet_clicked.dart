import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'adopt_pet_screen.dart'; // Import the new adopt screen

class PetDetailsScreen extends StatefulWidget {
  final int petId;

  PetDetailsScreen({required this.petId});

  @override
  _PetDetailsScreenState createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  Map<String, dynamic>? petDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    final url = Uri.parse("http://127.0.0.1:5566/users/pets/${widget.petId}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print("Raw API Response: $data"); // Debugging log

        if (data is Map<String, dynamic> && data.containsKey("data") && data["data"].containsKey("info")) {
          setState(() {
            petDetails = data["data"]["info"];
            isLoading = false;
          });
          print("Extracted Pet Details: $petDetails"); // Debugging log
        } else {
          print("Unexpected response format");
        }
      } else {
        print("Failed to load pet details. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching pet details: $e");
    }
  }

  void _onAdoptPressed() {
    if (petDetails != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdoptPetScreen(petId: widget.petId, petName: petDetails!["pet_name"] ?? "Unknown"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pet Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : petDetails == null
          ? Center(child: Text("Pet details not found"))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pet Image
            Container(
              margin: EdgeInsets.all(10),
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: petDetails?["pet_image"] != null
                    ? DecorationImage(
                  image: NetworkImage(petDetails!["pet_image"]),
                  fit: BoxFit.cover,
                )
                    : DecorationImage(
                  image: AssetImage("assets/images/logo.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Pet Details Below Image
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${petDetails?["pet_name"] ?? "Unknown"}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Age: ${petDetails?["pet_age"] ?? "N/A"}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  Text("Sex: ${petDetails?["pet_sex"] ?? "Unknown"}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  Text("Description: ${petDetails?["pet_descriptions"] ?? "No description available"}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 20),
                  // Adopt Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _onAdoptPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Adopt",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
