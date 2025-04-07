import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_pet.dart';

class PetDetailsScreen extends StatefulWidget {
  final int petId;
  final int shelterId; // Added shelterId to the constructor

  const PetDetailsScreen({super.key, required this.petId, required this.shelterId});

  @override
  _PetDetailsScreenState createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  Map<String, dynamic>? petData;
  bool isLoading = true;
  String errorMessage = '';
  Uint8List? petImage;

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    final url =
        'http://127.0.0.1:5566/shelter/${widget.petId}/petinfo'; // Adjusted URL to use petId
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging

        final petDataResponse =
            data['data']['pet']; // Adjusted to fetch the 'pet' object

        setState(() {
          petData = {
            'pet_id': petDataResponse['pet_id'],
            'shelter_id': petDataResponse['shelter_id'],
            'pet_name': petDataResponse['pet_name'],
            'pet_type': petDataResponse['pet_type'],
            'pet_descriptions': petDataResponse['pet_descriptions'],
            'pet_sex': petDataResponse['pet_sex'],
            'pet_age': petDataResponse['pet_age'],
            'age_type': petDataResponse['age_type'],
            'pet_image1': petDataResponse['pet_image1'] != null &&
                    petDataResponse['pet_image1'].isNotEmpty
                ? base64Decode(petDataResponse['pet_image1']
                    [0]) // Decode the first image (or handle multiple images)
                : null, // Handle case where no images are available
          };
          isLoading = false; // Set loading to false once data is fetched
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Pet Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        child: Stack(
                          children: [
                            // Main content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                    height: 30), // Space for the edit button
                                Center(
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundImage: petData?[
                                                    'pet_image1'] !=
                                                null
                                            ? MemoryImage(
                                                petData!['pet_image1'])
                                            : const AssetImage(
                                                    'assets/images/logo.png')
                                                as ImageProvider,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        petData?['pet_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Divider(thickness: 1, color: Colors.grey[400]),
                                const Text(
                                  'Pet Description',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  petData?['pet_descriptions'] ??
                                      'No description available.',
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(
                                      height: 1.5, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                Divider(thickness: 1, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                 _infoRow('Type of Pet', petData?['pet_type'] ?? 'Unknown'),
                                _infoRow('Sex', petData?['pet_sex']),
                                _infoRow(
                                  'Age (Approx.)',
                                  '${petData?['pet_age'] ?? 'Unknown'} ${petData?['age_type'] ?? ''} old',
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),

                            // Edit Button
                            Positioned(
                              top: 0,
                              left: 0,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditPetScreen(
                                        petId: widget.petId,
                                        shelterId: widget.shelterId, // <-- add this
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text("Edit",
                                    style: TextStyle(fontSize: 14)),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value ?? 'Unknown'),
      ],
    );
  }
}
