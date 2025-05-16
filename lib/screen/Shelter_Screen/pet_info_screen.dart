import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  int applicantCount = 0;
  List<Map<String, dynamic>> applicantsList = [];
  Map<String, dynamic>? petData;
  bool isLoading = true;
  String errorMessage = '';
  Uint8List? petImage;
  Uint8List? petVaccine;

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = 'http://127.0.0.1:5566/api/shelter/${widget.petId}/petinfo';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print("Full response body: $body"); // Debugging

        if (body is Map<String, dynamic> && body['data'] != null) {
          final data = body['data'];

          // Decode base64 image if exists
          if (data['petmedia'] != null &&
              data['petmedia']['pet_image1'] != null &&
              data['petmedia']['pet_image1'] is String) {
            data['petmedia']['pet_image1'] =
                base64Decode(data['petmedia']['pet_image1']);
          }

          if (data['petmedia'] != null &&
              data['petmedia']['pet_vaccine'] != null &&
              data['petmedia']['pet_vaccine'] is String) {
            data['petmedia']['pet_vaccine'] =
                base64Decode(data['petmedia']['pet_vaccine']);
          }

          setState(() {
            isLoading = false;
            petData = data;
          });
        } else {
          print("Invalid response format or 'Data' is null.");
        }
      } else {
        print(
            "Failed to load shelter info. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching shelter info: $e");
    }
  }

  Future<void> archivePets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.petId}/archive-pet'; // Adjusted URL to use petId
    try {
      final response = await http.put(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
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

  Future<void> unarchivePets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.petId}/unarchive-pet'; // Adjusted URL to use petId
    try {
      final response = await http.put(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging

        if (data['retCode'] == '200') {
          // Handle success
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Pet moved to unarchive successfully.')),
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

  Future<void> togglePriorityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.petId}/pet/update-priority-status';
    try {
      final response = await http.put(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
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


  void showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Dim background
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(imageBytes),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
         backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 40,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Pet Information',
                                  style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.lightBlue),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.notifications),
                                    onPressed: () {}),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                                                            'petmedia'] !=
                                                        null &&
                                                    petData!['petmedia']
                                                            ['pet_image1'] !=
                                                        null
                                                ? MemoryImage(
                                                    petData!['petmedia']
                                                        ['pet_image1'])
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
                                  Navigator.pop(context,
                                      true); // Go back to the previous screen
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                iconSize: 40,
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
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vaccination Image',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    if (petData?['petmedia']?['pet_vaccine'] !=
                                        null) {
                                      showFullScreenImage(
                                        context,
                                        petData!['petmedia']['pet_vaccine'],
                                      );
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: petData?['petmedia']
                                                ?['pet_vaccine'] !=
                                            null
                                        ? Image.memory(
                                            petData!['petmedia']['pet_vaccine'],
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/logo.png',
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        petData?['status'] == 'available'
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize:
                                        const Size(double.infinity, 50),
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
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                        const SizedBox(height: 10),
                        petData?['status'] == 'available'
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize:
                                        const Size(double.infinity, 50),
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
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text("No"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              "Yes",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await archivePets(); // your function to archive
                                    }
                                  },
                                  child: Text(
                                    'Move to Archive',
                                    style: GoogleFonts.poppins(
                                        color: Colors.red, fontSize: 16),
                                  ),
                                ),
                              )
                            : petData?['status'] == 'archived'
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        minimumSize:
                                            const Size(double.infinity, 50),
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            content: const Text(
                                                "Are you sure you want to unarchive this pet?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text("No"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text(
                                                  "Yes",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await unarchivePets(); // your function to unarchive
                                        }
                                      },
                                      child: Text(
                                        'Unarchive Pet',
                                        style: GoogleFonts.poppins(
                                            color: Colors.green, fontSize: 16),
                                      ),
                                    ),
                                  )
                                : const SizedBox(), // No button if status is neither "available" nor "archived"
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
        Text(
          value ?? 'Unknown',
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }
}

class ApplicantListModal extends StatelessWidget {
  final int applicationId;
  final int petId;
  final List<Map<String, dynamic>> applicants;

  const ApplicantListModal({super.key, required this.applicants, required this.applicationId, required this.petId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          controller: controller,
          itemCount: applicants.length,
          itemBuilder: (context, index) {
            final applicant = applicants[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${index + 1}.',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: applicant['adopter_profile_decoded'] !=
                              null
                          ? MemoryImage(applicant['adopter_profile_decoded'])
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                  ],
                ),
                title: Text(
                  '${applicant['first_name']} ${applicant['last_name']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Chosen Pet: ${applicant['pet_name']}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            );
          },
        ),
      ),
    );
  }
}