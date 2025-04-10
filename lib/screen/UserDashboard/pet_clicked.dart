import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/adopt_pet_screen.dart';
import 'temporary_adopt_screen.dart';

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
        if (data is Map<String, dynamic> &&
            data.containsKey("data") &&
            data["data"].containsKey("info")) {
          setState(() {
            petDetails = data["data"]["info"];
            isLoading = false;
          });
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
          builder: (context) => AdoptPetScreen(
            petId: widget.petId,
            petName: petDetails!["pet_name"] ?? "Unknown",
          ),
        ),
      );
    }
  }

  Widget _buildBase64Image(String? base64String, {double radius = 60}) {
    if (base64String == null || base64String.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage("assets/images/logo.png") as ImageProvider,
      );
    }

    try {
      // Remove potential data:image/*;base64, prefix if present
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;

      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(base64Decode(cleanBase64)),
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage("assets/images/logo.png") as ImageProvider,
        child: Icon(Icons.error, color: Colors.red),
      );
    }
  }

  void _showFullImage() {
    if (petDetails == null || petDetails!["pet_image1"] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image available')),
      );
      return;
    }

    final base64String = petDetails!["pet_image1"];

    try {
      // Remove potential data:image/*;base64, prefix if present
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: EdgeInsets.all(20),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: MemoryImage(base64Decode(cleanBase64)),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error showing full image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to display image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = petDetails;
    return Scaffold(
      appBar: AppBar(
        title: Text("Pet Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : pet == null
          ? Center(child: Text("Pet details not found"))
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pet circular image - now clickable with base64 support
            GestureDetector(
              onTap: _showFullImage,
              child: _buildBase64Image(pet["pet_image1"]),
            ),
            SizedBox(height: 16),

            // Pet name and breed
            Text(
              pet["pet_name"] ?? "Unknown",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "${pet["pet_type"] ?? "Type"}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),

            // Description
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Description",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pet["pet_descriptions"] ??
                    "No description available.",
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 24),

            // Info rows: Gender, Size, Weight
            _infoRow("Gender", "${pet["pet_sex"] ?? "Unknown"}"),
            _infoRow("Age", "${pet["pet_age"] ?? "N/A"}"),

            SizedBox(height: 40),

            // Adopt Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onAdoptPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Adopt",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        ],
      ),
    );
  }
}