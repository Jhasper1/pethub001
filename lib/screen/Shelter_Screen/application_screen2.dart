import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_bar.dart';
import 'application_details_screen.dart'; // Import the details screen

class ApplicantsScreen2 extends StatefulWidget {
  final int shelterId;

  const ApplicantsScreen2({super.key, required this.shelterId});

  @override
  State<ApplicantsScreen2> createState() => _ApplicantsScreen2State();
}

class _ApplicantsScreen2State extends State<ApplicantsScreen2> {
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() => isLoading = true);
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.shelterId}/adoption';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> pets = json.decode(response.body)['data'];
      List<Map<String, dynamic>> loadedApplicants = [];

      for (var pet in pets) {
        final petId = pet['pet_id'];
        final countUrl =
            'http://127.0.0.1:5566/api/shelter/count/$petId/applied';
        final countResponse = await http.get(
          Uri.parse(countUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );

        int totalCount = 0;
        if (countResponse.statusCode == 200) {
          totalCount = json.decode(countResponse.body)['data'];
        }

        // Decode base64 image if present
        Uint8List? image;
        if (pet['petmedia'] != null && pet['petmedia']['pet_image1'] != null) {
          image = base64Decode(pet['petmedia']['pet_image1']);
        }

        loadedApplicants.add({
          'pet_id': petId,
          'pet_name': pet['pet_name'],
          'count': totalCount,
          'petmedia': {'pet_image1': image},
          'application_id': pet['application_id'].toString(), // Optional
        });
      }

      setState(() {
        applicants = loadedApplicants;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('Failed to load applicants');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                      'Applications',
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
            SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Here is the list of applications:",
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: applicants.isEmpty
                        ? Center(
                            child: Text('No applications found.',
                                style: GoogleFonts.poppins()))
                        : ListView.builder(
                            itemCount: applicants.length,
                            itemBuilder: (context, index) {
                              final applicant = applicants[index];
                              return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) => PetApplicantsModal(
                                      petId: applicant['pet_id'],
                                    ),
                                  );
                                },
                                child: Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${index + 1}.',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundImage: applicant['petmedia']
                                                      ['pet_image1'] !=
                                                  null
                                              ? MemoryImage(
                                                  applicant['petmedia']
                                                      ['pet_image1'])
                                              : AssetImage(
                                                      'assets/images/logo.png')
                                                  as ImageProvider,
                                        ),
                                      ],
                                    ),
                                    title: Text('${applicant['pet_name']}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        'Total Applications: ${applicant['count']}',
                                        style:
                                            GoogleFonts.poppins(fontSize: 12)),
                                    trailing: Icon(Icons.arrow_forward_ios),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}

class PetApplicantsModal extends StatefulWidget {
  final int petId;

  const PetApplicantsModal({
    super.key,
    required this.petId,
  });

  @override
  State<PetApplicantsModal> createState() => _PetApplicantsModalState();
}

class _PetApplicantsModalState extends State<PetApplicantsModal> {
  List<dynamic> petApplicants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPetApplicants();
  }
Future<void> fetchPetApplicants() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final url = 'http://127.0.0.1:5566/api/shelter/${widget.petId}/get/applications'; // Replace with your actual URL

  final response = await http.get(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",  // Use the token for authentication
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    
    // Assuming the data is a list of applicants
    setState(() {
      petApplicants = (data as List).map((app) => _mapApplicant(app)).toList();
      isLoading = false;
    });
  } else {
    setState(() => isLoading = false);
    print("Failed to load pet applicants: ${response.statusCode}");
  }
}

Map<String, dynamic> _mapApplicant(dynamic app) {
  return {
    'application_id': app['application_id'],
    'first_name': app['first_name'],
    'last_name': app['last_name'],
    'adopter_profile': app['adopter_profile'], // Raw base64 string
    'adopter_profile_decoded': _decodeBase64Image(app['adopter_profile']), // Decoded image
    'status': app['status'],
    'created_at': app['created_at'],
  };
}

Uint8List? _decodeBase64Image(String? base64String) {
  if (base64String == null || base64String.isEmpty) {
    return null; // If the string is null or empty, return null
  }
  try {
    final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
    base64String = base64String.replaceAll(regex, ''); // Remove any potential prefix
    return base64Decode(base64String);
  } catch (e) {
    print("Error decoding Base64 image: $e");
    return null;
  }
}
@override
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(16),
    height: MediaQuery.of(context).size.height * 0.75,
    child: isLoading
        ? Center(child: CircularProgressIndicator())
        : petApplicants.isEmpty
            ? Center(child: Text("No applicants yet"))
            : ListView.builder(
                itemCount: petApplicants.length,
                itemBuilder: (context, index) {
                  final applicant = petApplicants[index];

                  // Check for decoded adopter profile image
                  final adopterProfile = applicant['adopter_profile_decoded'] != null
                      ? MemoryImage(applicant['adopter_profile_decoded'])
                      : AssetImage('assets/images/logo.png') as ImageProvider;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplicationDetailsScreen(
                            applicationId: applicant['application_id'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${index + 1}.',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            // Circle Avatar displaying profile picture
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: adopterProfile,
                            ),
                          ],
                        ),
                        title: Text(
                            '${applicant['first_name']} ${applicant['last_name']}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  );
                },
              ),
  );
}
}