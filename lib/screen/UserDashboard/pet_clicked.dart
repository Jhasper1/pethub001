import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PetDetailsScreen extends StatefulWidget {
  final int petId; // Receive pet_id instead of whole pet object

  PetDetailsScreen({required this.petId});

  @override
  _PetDetailsScreenState createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  Map? petDetails; // Store fetched pet details
  bool isLoading = true; // Show loading state

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    final url = Uri.parse("http://127.0.0.1:5566/pets/${widget.petId}"); // Replace with actual API URL

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          petDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print("Failed to load pet details. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching pet details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(petDetails?["pet_name"] ?? "Pet Details")),
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
                image: petDetails!["pet_image"] != null
                    ? DecorationImage(
                  image: NetworkImage(petDetails!["pet_image"]),
                  fit: BoxFit.cover,
                )
                    : DecorationImage(
                  image: AssetImage("assets/images/logo.png"), // Placeholder
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Pet Details
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${petDetails!["pet_name"]}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Age: ${petDetails!["pet_age"]}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  Text("Sex: ${petDetails!["pet_sex"]}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 10),
                  Text("Description: ${petDetails!["pet_description"]}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
