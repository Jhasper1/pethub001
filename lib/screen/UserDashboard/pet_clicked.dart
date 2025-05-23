import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/shelter_clicked.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adoption_submission2.dart';

class UserPetDetailsScreen extends StatefulWidget {
  final int petId;
  final int adopterId;
  final int shelterId; // Assuming a default shelter ID for now

  UserPetDetailsScreen(
      {required this.petId, required this.adopterId, required this.shelterId});

  @override
  _UserPetDetailsScreenState createState() => _UserPetDetailsScreenState();
}

class _UserPetDetailsScreenState extends State<UserPetDetailsScreen> {
  Map<String, dynamic>? petData;
  Map<String, dynamic>? ShelterInfo;
  List<Map<String, dynamic>> otherPets = [];
  List<dynamic> pets = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
    fetchShelterInfo();
    fetchPets();
  }

  Future<void> fetchPetDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        Uri.parse("http://127.0.0.1:5566/api/users/pets/${widget.petId}");

    try {
      final response = await http.get(url, headers: {
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

        // Decode pet_vaccine if it exists and is base64
        if (petData?['petmedia']?['pet_vaccine'] != null) {
          final base64String = petData!['petmedia']['pet_vaccine'];
          petData!['petmedia']['pet_vaccine'] = base64Decode(base64String);
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

  Future<void> fetchShelterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = 'http://127.0.0.1:5566/api/shelter/${widget.shelterId}/refined';

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
          if (data['sheltermedia'] != null &&
              data['sheltermedia']['shelter_profile'] != null &&
              data['sheltermedia']['shelter_profile'] is String) {
            data['sheltermedia']['shelter_profile'] =
                base64Decode(data['sheltermedia']['shelter_profile']);
          }

          setState(() {
            ShelterInfo = data;
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

  Future<void> fetchPets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse(
        'http://127.0.0.1:5566/api/adopter/get/${widget.shelterId}/other-pets');

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded['data'] != null) {
          final data = decoded['data'] as Map<String, dynamic>;
          final petsRaw = data['pets'];

          final allPets = List<Map<String, dynamic>>.from(
            (petsRaw as List).map((e) => Map<String, dynamic>.from(e)),
          );

          for (var pet in allPets) {
            final media = pet['petmedia'] ?? pet['PetMedia'];
            if (media != null &&
                media['pet_image1'] != null &&
                media['pet_image1'] is String) {
              try {
                // Remove prefix if exists
                final base64Str = media['pet_image1'].split(',').last;
                media['pet_image1'] = base64Decode(base64Str);
              } catch (e) {
                print("Decode failed for pet ${pet['pet_id']}: $e");
              }
            }
          }

          setState(() {
            pets = allPets;

            // Filter out current pet
            final filteredPets =
                allPets.where((pet) => pet['pet_id'] != widget.petId).toList();

            // Shuffle and take 4
            filteredPets.shuffle();
            otherPets = filteredPets.take(4).toList();

            isLoading = false;
          });
        } else {
          print("No data found in response: ${decoded['message']}");
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("Request failed: ${response.statusCode} - ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error during request: $e");
      setState(() {
        isLoading = false;
      });
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

  Future<void> _onAdoptPressed() async {
    final uri = Uri.parse(
      'http://127.0.0.1:5566/check_application?petId=${widget.petId}&adopterId=${widget.adopterId}',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final petAndAdopter = data['pet_and_adopter'] == true;
      final adopterExists = data['adopter_exists'] == true;

      if (petAndAdopter) {
        // Exact match: this adopter already applied for this specific pet
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Already Applied'),
            content: const Text(
                'You have already submitted an application for this pet.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (adopterExists) {
        // Adopter has other pending applications
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pending Application'),
            content:
                const Text('You still have a pending adoption application.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Proceed to form (no existing application found)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdoptionForm(
              petId: widget.petId,
              adopterId: widget.adopterId,
              shelterId: widget.shelterId,
            ),
          ),
        );
      }
    } else {
      // Error response
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text(
              'Something went wrong while checking application status.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
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
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        title: Text('Pet Information',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      backgroundColor: const Color.fromARGB(255, 239, 250, 255),
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
                            // ... inside your build method, before the main GridView list
                            Card(
                              color: const Color.fromARGB(255, 255, 255, 255),
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
                                        if (petData?['petmedia']
                                                ?['pet_vaccine'] !=
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
                                                petData!['petmedia']
                                                    ['pet_vaccine'],
                                                height: 200,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                'assets/images/noimage2.webp',
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

                            Card(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: ShelterInfo != null &&
                                          ShelterInfo!['sheltermedia'] !=
                                              null &&
                                          ShelterInfo!['sheltermedia']
                                                  ['shelter_profile'] !=
                                              null
                                      ? MemoryImage(ShelterInfo!['sheltermedia']
                                          ['shelter_profile'])
                                      : AssetImage('assets/images/logo.png')
                                          as ImageProvider,
                                ),
                                title: Text(
                                  ShelterInfo?['shelter_name'] ??
                                      'Unknown Shelter',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  ShelterInfo?['shelter_address'] ??
                                      'No address provided',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                trailing: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ShelterDetailsScreen(
                                          shelterId: widget.shelterId,
                                          adopterId: widget.adopterId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'View',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 24),

                            Text(
                              "More Pets from ${ShelterInfo?['shelter_name']} :",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 15),

                            otherPets.isEmpty
                                ? Text("No other pets available.",
                                    style: GoogleFonts.poppins())
                                : SizedBox(
                                    height: 220, // adjust height to fit cards
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: otherPets.length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(width: 10),
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: 150,
                                          child:
                                              _buildPetCard(otherPets[index]),
                                        );
                                      },
                                    ),
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            "Adopt Now",
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

  Widget _buildPetCard(Map<String, dynamic> pet) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserPetDetailsScreen(
              petId: pet['pet_id'],
              adopterId: widget.adopterId,
              shelterId: pet['shelter_id'],
            ),
          ),
        );
        if (result == true) {
          fetchPets();
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      pet['petmedia'] != null &&
                              pet['petmedia']['pet_image1'] != null
                          ? Image.memory(
                              pet['petmedia']['pet_image1'],
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                      Container(
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ],
                  ),
                )
              ],
            ),
            // Pet name
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  pet['pet_name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // Star icon
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                pet['priority_status'] == true ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
