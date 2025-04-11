import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/adopt_pet_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final int petId;

  PetDetailsScreen({required this.petId});

  @override
  _PetDetailsScreenState createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  Map<String, dynamic>? petDetails;
  bool isLoading = true;
  bool hasError = false;

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
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        print("Failed to load pet details. Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print("Error fetching pet details: $e");
    }
  }

  void _onAdoptPressed() {
    if (petDetails != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionnaireScreen(
            petId: widget.petId,
            petName: petDetails!["pet_name"] ?? "Unknown",
          ),
        ),
      );
    }
  }

  Widget _buildSquareImage(String? base64String) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageSize = screenWidth - 32;

    if (base64String == null || base64String.isEmpty) {
      return SizedBox(
        width: imageSize,
        height: imageSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            "assets/images/logo.png",
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    try {
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;

      return SizedBox(
        width: imageSize,
        height: imageSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            base64Decode(cleanBase64),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return SizedBox(
        width: imageSize,
        height: imageSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            "assets/images/logo.png",
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  Widget _squareInfoBox(String label, String? value, Color color) {
    return Container(
      width: 120,
      height: 90,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black45),
            ),
            SizedBox(height: 6),
            Text(
              value ?? "N/A",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pet Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError || petDetails == null
          ? Center(
        child: Text(
          "Failed to load pet details.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : Stack(
        children: [
          SingleChildScrollView(
            padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSquareImage(petDetails!["pet_image1"]),
                SizedBox(height: 16),
                Text(
                  petDetails!["pet_name"] ?? "Unknown",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _squareInfoBox("Type", petDetails!["pet_type"],
                        Color(0xFFFFEFED)),
                    _squareInfoBox("Gender", petDetails!["pet_sex"],
                        Color(0xFFEDF2FF)),
                    _squareInfoBox(
                        "Age",
                        petDetails!["pet_age"]?.toString(),
                        Color(0xFFEBF8F3)),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  "Description",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  petDetails!["pet_descriptions"] ??
                      "No description available.",
                  style: TextStyle(
                      fontSize: 15, color: Colors.grey[700]),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onAdoptPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color(0xFF1B85F3), // Teal 500
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Adopt",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
