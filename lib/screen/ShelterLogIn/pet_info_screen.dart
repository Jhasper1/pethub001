import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes

class PetDetailsScreen extends StatefulWidget {
  final int petId;

  const PetDetailsScreen({super.key, required this.petId});

  @override
  _PetDetailsScreenState createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  Map<String, dynamic>? petData; // Store fetched pet details
  bool isLoading = true; // Loading state
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    final url = 'http://127.0.0.1:5566/shelter/${widget.petId}/petinfo';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        print("API Response: $responseJson");

        if (responseJson['data'] != null &&
            responseJson['data'] is Map<String, dynamic>) {
          setState(() {
            petData = responseJson['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "No pet data found.";
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load pet data');
      }
    } catch (e) {
      print("Error fetching pet data: $e");
      setState(() {
        errorMessage = "Error fetching pet data.";
        isLoading = false;
      });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Pet Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: petData!['pet_image1'] !=
                              null &&
                              petData!['pet_image1'].isNotEmpty
                              ? _getImageFromBase64(petData!['pet_image1'])
                              : AssetImage('assets/images/logo.png')
                          as ImageProvider,
                        ),
                        SizedBox(height: 10),
                        Text(
                          petData!['pet_name'] ?? 'Unknown',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('${petData!['pet_type'] ?? 'Unknown'}',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Pet Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    petData!['pet_descriptions'] ??
                        'No description available.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 16),
                  Divider(thickness: 1, color: Colors.grey[400]),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gender',
                          style:
                          TextStyle(fontWeight: FontWeight.bold)),
                      Text(petData!['pet_sex'] ?? 'Unknown'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ID',
                          style:
                          TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.petId}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Age',
                          style:
                          TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          '${petData!['pet_age'] ?? 'Unknown'} ${petData!['age_type'] ?? ''}'),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Function to handle base64 image decoding and return Image
  ImageProvider _getImageFromBase64(String base64String) {
    try {
      final decodedImage = _decodeBase64Image(base64String);
      if (decodedImage != null) {
        return MemoryImage(decodedImage);
      }
    } catch (e) {
      print("Error loading image from base64: $e");
    }
    return AssetImage('assets/images/logo.png') as ImageProvider; // Fallback
  }
}