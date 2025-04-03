import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pet_clicked.dart'; // Import PetDetailsPage

class ShelterDetailsPage extends StatefulWidget {
  final int shelterId;

  const ShelterDetailsPage({Key? key, required this.shelterId}) : super(key: key);

  @override
  _ShelterDetailsPageState createState() => _ShelterDetailsPageState();
}

class _ShelterDetailsPageState extends State<ShelterDetailsPage> {
  Map<String, dynamic>? shelterDetails;
  List<dynamic> pets = [];
  bool isLoading = true;
  bool shelterLoaded = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchShelterDetails();
  }

  Future<void> fetchShelterDetails() async {
    final shelterUrl = Uri.parse("http://127.0.0.1:5566/users/shelters/${widget.shelterId}");
    final petsUrl = Uri.parse("http://127.0.0.1:5566/shelter/${widget.shelterId}/pets");

    try {
      final shelterResponse = await http.get(shelterUrl);
      if (shelterResponse.statusCode == 200) {
        final shelterData = json.decode(shelterResponse.body);
        setState(() {
          shelterDetails = shelterData["data"]["info"];
          shelterLoaded = true;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load shelter details (Status: ${shelterResponse.statusCode})";
          isLoading = false;
        });
        return;
      }

      final petsResponse = await http.get(petsUrl);
      if (petsResponse.statusCode == 200) {
        final petsData = json.decode(petsResponse.body);
        setState(() {
          pets = petsData["data"] ?? [];
          isLoading = false;
        });
      } else if (petsResponse.statusCode == 404) {
        setState(() {
          pets = [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load pets (Status: ${petsResponse.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching shelter details and pets: $e";
        isLoading = false;
      });
    }
  }

  void _onPetClicked(int petId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailsScreen(petId: petId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shelter Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : shelterLoaded
          ? Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: shelterDetails?["shelter_image"] != null
                      ? NetworkImage(shelterDetails!["shelter_image"])
                      : AssetImage("assets/images/logo.png") as ImageProvider,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelterDetails?["shelter_name"] ?? "Shelter Name Not Found",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text("📍 ${shelterDetails?["shelter_address"] ?? "Not Available"}"),
                      SizedBox(height: 5),
                      Text("📞 ${shelterDetails?["shelter_contact"] ?? "Not Available"}"),
                      SizedBox(height: 5),
                      Text("📧 ${shelterDetails?["shelter_email"] ?? "Not Available"}"),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text("Available Pets:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            pets.isEmpty
                ? Center(child: Text("No pets available for adoption", style: TextStyle(color: Colors.grey)))
                : Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return GestureDetector(
                    onTap: () => _onPetClicked(pet["id"]),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              pet["pet_image"] ?? "assets/images/logo.png",
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              pet["pet_name"] ?? "Unknown Pet",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      )
          : Center(child: Text("No shelter details available", style: TextStyle(color: Colors.grey))),
    );
  }
}
