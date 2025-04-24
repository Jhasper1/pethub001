import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'edit_pet_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final int petId;
  final int shelterId; 

  const PetDetailsScreen(
      {super.key, required this.petId, required this.shelterId});

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
            'pet_size': petDataResponse['pet_size'],
            'age_type': petDataResponse['age_type'],
            'priority_status': petDataResponse['priority_status'],
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

  Future<void> archivePets() async {
    final url =
        'http://127.0.0.1:5566/shelter/${widget.petId}/archive-pet'; // Adjusted URL to use petId
    try {
      final response = await http.put(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging

        if (data['retCode'] == '200') {
          // Handle success
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet moved to archive successfully.')),
          );
          // Return true to indicate success
        } else {
          // Handle failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to archive pet.')),
          );

          setState(() {
            errorMessage = "Failed to archive pet.";
          });
        }
      } else {
        throw Exception('Failed to archive pet');
      }
    } catch (e) {
      print("Error archiving pet: $e");
      setState(() {
        errorMessage = "Error archiving pet.";
      });
    }
  }

  Future<void> togglePriorityStatus() async {
    final url =
        'http://127.0.0.1:5566/shelter/${widget.petId}/pet/update-priority-status';
    try {
      final response = await http.put(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        if (data['retCode'] == '200') {
          // Explicitly toggle the status locally
          setState(() {
            // Flip the boolean based on the current value
            petData!['priority_status'] =
                !(petData!['priority_status'] ?? false);
          });

          // Refresh the whole screen data
          await fetchPetDetails();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Priority status updated.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update priority.')),
          );
        }
      } else {
        throw Exception('Failed to update priority status');
      }
    } catch (e) {
      print("Error updating priority: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while updating.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2F3FD),
      appBar: AppBar(
        title: Text(
          'Pet Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
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
                        Stack(
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
                                          const SizedBox(height: 50),
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(
                                        thickness: 1, color: Colors.grey[400]),
                                    const SizedBox(height: 10),
                                    _infoRow('Type of Pet',
                                        petData?['pet_type'] ?? 'Unknown'),
                                    const SizedBox(height: 8),
                                    _infoRow('Sex', petData?['pet_sex']),
                                    const SizedBox(height: 8),
                                    _infoRow(
                                      'Age ',
                                      '(Approx.) ${petData?['pet_age'] ?? 'Unknown'} ${petData?['age_type'] ?? ''} old',
                                    ),
                                    const SizedBox(height: 8),
                                    _infoRow('Size',
                                        '${petData?['pet_size'] ?? 'Unknown'} KG'),
                                    const SizedBox(height: 10),
                                    Divider(
                                        thickness: 1, color: Colors.grey[400]),
                                    Text(
                                      'Pet Description',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      petData?['pet_descriptions'] ??
                                          'No description available.',
                                      // textAlign: TextAlign.justify,
                                      style: GoogleFonts.poppins(
                                          height: 1.5, fontSize: 13),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.black),
                                onPressed: () {
                                  Navigator.pop(
                                      context, true); // Go back to the previous screen
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                iconSize: 30,
                                icon: Icon(
                                  petData?['priority_status'] == true
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: petData?['priority_status'] == true
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: const Text(
                                        "Are you sure you want to change the priority status of this pet?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await togglePriorityStatus();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
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
                            child: Text(
                              'Edit Pet Profile',
                              style:
                                  GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  content: const Text(
                                      "Are you sure you want to move this pet to archive?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        "Yes",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await archivePets();
                              }
                            },
                            child: Text(
                              'Move to Archive',
                              style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
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
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        Text(value ?? 'Unknown', style: GoogleFonts.poppins(),),
      ],
    );
  }
}
