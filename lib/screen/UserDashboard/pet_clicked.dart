import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'adoption_submission.dart';

class UserPetDetailsScreen extends StatefulWidget {
  final int petId;
  final int adopterId;

  UserPetDetailsScreen({required this.petId, required this.adopterId});

  @override
  _UserPetDetailsScreenState createState() => _UserPetDetailsScreenState();
}

class _UserPetDetailsScreenState extends State<UserPetDetailsScreen> {
  Map<String, dynamic>? petData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
        final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse("http://127.0.0.1:5566/api/users/pets/${widget.petId}");

    try {
      final response = await http.get(url,
      headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          });
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response structures
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            // Case 1: Data is nested under "data"
            if (data['data'] is Map && data['data'].containsKey('pet')) {
              petData = Map<String, dynamic>.from(data['data']['pet']);
            } else {
              petData = Map<String, dynamic>.from(data['data']);
            }
          } else {
            // Case 2: Data is at root level
            petData = data;
          }
        }

        print("Extracted petData: $petData");

        setState(() {
          isLoading = false;
          hasError = petData == null;
        });
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
    if (petData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdoptionSubmissionForm(
            petId: widget.petId,
            petName: _getPetField('name') ?? "Unknown",
            adopterId: widget.adopterId,
          ),
        ),
      );
    }
  }

  // Helper method to get field with multiple possible keys
  String? _getPetField(String fieldName) {
    if (petData == null) return null;

    // Try different key variations
    final possibleKeys = [
      fieldName,
      'pet_$fieldName',
      '${fieldName}_pet',
      fieldName.toLowerCase(),
      fieldName.toUpperCase(),
    ];

    for (var key in possibleKeys) {
      if (petData!.containsKey(key)) {
        return petData![key]?.toString();
      }
    }
    return null;
  }

  Widget _buildSquareImage(String? imageData) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageSize = screenWidth - 32;

    if (imageData == null || imageData.isEmpty) {
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
      final cleanBase64 =
          imageData.contains(',') ? imageData.split(',').last : imageData;

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
      width: 100,
      height: 80,
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
                color: Colors.black45,
              ),
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
          : hasError || petData == null
              ? Center(
                  child: Text(
                    "Failed to load pet details.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSquareImage(
                                petData?['petmedia']?['pet_image1']),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                Text(
                                  _getPetField('pet_name') ?? "Unknown",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                    width: 2), // spacing between name and icon

                                if (_getPetField('pet_sex')?.toLowerCase() ==
                                    'male') ...[
                                  Icon(Icons.male,
                                      color: Colors.blue, size: 30),
                                ] else if (_getPetField('pet_sex')
                                        ?.toLowerCase() ==
                                    'female') ...[
                                  Icon(Icons.female,
                                      color: Colors.pink, size: 30),
                                ],
                              ],
                            ),
                            SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _squareInfoBox("Type", _getPetField('pet_type'),
                                    Color(0xFFFFEFED)),
                                _squareInfoBox(
                                    "Weight",
                                    "${_getPetField('pet_size')} kg",
                                    Color(0xFFEDF2FF)),
                                _squareInfoBox(
                                    "Age",
                                    "${_getPetField('pet_age')} ${_getPetField('age_type')}",
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
                              _getPetField('pet_descriptions') ??
                                  "No description available.",
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onAdoptPressed,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Color(0xFF1B85F3),
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
                    ),
                  ],
                ),
    );
  }
}
