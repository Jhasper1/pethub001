import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_pet_screen.dart';
import 'bottom_nav_bar.dart'; // Import the updated BottomNavigationBar widget

class ArchivedPetInfoScreen extends StatefulWidget {
  final int petId;
  final int shelterId; // Added shelterId to the constructor

  const ArchivedPetInfoScreen(
      {super.key, required this.petId, required this.shelterId});

  @override
  _ArchivedPetInfoScreenState createState() => _ArchivedPetInfoScreenState();
}

class _ArchivedPetInfoScreenState extends State<ArchivedPetInfoScreen> {
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

  Future<void> unarchivePets() async {
    final url =
        'http://127.0.0.1:5566/shelter/${widget.petId}/unarchive-pet'; // Adjusted URL to use petId
    try {
      final response = await http.put(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging

        if (data['retCode'] == '200') {
          // Handle success
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet moved to unarchive successfully.')),
          );
          // Return true to indicate success
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to unarchive pet.')),
          );

          setState(() {
            errorMessage = "Failed to unarchive pet.";
          });
        }
      } else {
        throw Exception('Failed to unarchive pet');
      }
    } catch (e) {
      print("Error unarchiving pet: $e");
      setState(() {
        errorMessage = "Error unarchiving pet.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 1,
      ),
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Pet Profile'),
        backgroundColor: Colors.lightBlue,
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
                    child: Column(
                      children: [
                        Card(
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
                                        radius: 75,
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
                                const SizedBox(height: 10),
                                Divider(thickness: 1, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                _infoRow('Type of Pet',
                                    petData?['pet_type'] ?? 'Unknown'),
                                _infoRow('Sex', petData?['pet_sex']),
                                _infoRow(
                                  'Age ',
                                  '(Approx.) ${petData?['pet_age'] ?? 'Unknown'} ${petData?['age_type'] ?? ''} old',
                                ),
                                const SizedBox(height: 10),
                                Divider(thickness: 1, color: Colors.grey[400]),
                                const Text(
                                  'Pet Description',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  petData?['pet_descriptions'] ??
                                      'No description available.',
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(
                                      height: 1.5, fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Edit Button below the card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditPetScreen(
                                    petId: widget.petId,
                                    shelterId: widget.shelterId,
                                  ),
                                ),
                              );
                              if (result == true) {
                                fetchPetDetails();
                              }
                            },
                            child: const Text(
                              'Edit Pet Profile',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  // title: const Text("Confirm Archive"),
                                  content: const Text(
                                      "Are you sure you want to unarchive this pet?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        "Confirm",
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await unarchivePets(); // Call the archive function only if confirmed
                              }
                            },
                            child: const Text(
                              'Unarchive Pet',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
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
