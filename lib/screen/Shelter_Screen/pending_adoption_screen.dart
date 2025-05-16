import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'application_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_bar.dart';
import 'application_details_screen.dart'; // Import the details screen

class PendingApplicantsScreen extends StatefulWidget {
  final int shelterId;

  const PendingApplicantsScreen({super.key, required this.shelterId});

  @override
  State<PendingApplicantsScreen> createState() =>
      _PendingApplicantsScreenState();
}

class _PendingApplicantsScreenState extends State<PendingApplicantsScreen> {
  List<String> sortOptions = ['Count ↑', 'Count ↓', 'A-Z', 'Z-A'];
  String selectedSort = 'Count ↑'; // Default sort
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplicants(sortOption: getSortKey(selectedSort));
  }

  String getSortKey(String sortLabel) {
    switch (sortLabel) {
      case 'Count ↑':
        return 'count_desc';
      case 'Count ↓':
        return 'count_asc';
      case 'A-Z':
        return 'az';
      case 'Z-A':
        return 'za';
      default:
        return 'count_desc';
    }
  }

  Future<void> fetchApplicants({String sortOption = 'count'}) async {
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

        Uint8List? image;
        if (pet['petmedia'] != null && pet['petmedia']['pet_image1'] != null) {
          image = base64Decode(pet['petmedia']['pet_image1']);
        }

        loadedApplicants.add({
          'pet_id': petId,
          'pet_name': pet['pet_name'],
          'status': pet['status'],
          'count': totalCount,
          'petmedia': {'pet_image1': image},
          'application_id': pet['application_id'].toString(),
        });
      }

      // Sort based on selected option
      if (sortOption == 'count_desc') {
        loadedApplicants
            .sort((a, b) => b['count'].compareTo(a['count'])); // High to Low
      } else if (sortOption == 'count_asc') {
        loadedApplicants
            .sort((a, b) => a['count'].compareTo(b['count'])); // Low to High
      } else if (sortOption == 'az') {
        loadedApplicants.sort((a, b) => a['pet_name']
            .toString()
            .toLowerCase()
            .compareTo(b['pet_name'].toString().toLowerCase()));
      } else if (sortOption == 'za') {
        loadedApplicants.sort((a, b) => b['pet_name']
            .toString()
            .toLowerCase()
            .compareTo(a['pet_name'].toString().toLowerCase()));
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
       backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 3,
      ),
     floatingActionButton: FloatingActionButton.extended(
  backgroundColor: Colors.lightBlue,
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ApplicantsScreen(shelterId: widget.shelterId),
      ),
    );
  },
  icon: const Icon(Icons.assignment, color: Colors.white),
  label: Text('View Applications',
  style: GoogleFonts.poppins( color: Colors.white,)),
),
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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
                      'Adoption Request',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${applicants.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedSort,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSort = value;
                          });
                          fetchApplicants(sortOption: getSortKey(value));
                        }
                      },
                      items: sortOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      icon: const Icon(Icons.sort),
                      underline: Container(height: 2, color: Colors.lightBlue),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Here is the list of chosen pets:",
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
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${index + 1}.',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(width: 10),
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

  String formatDateTime(String rawDateTime) {
    final dateTime = DateTime.parse(rawDateTime).toLocal();
    final formatter = DateFormat('MMM d, y | h:mm a');
    return formatter.format(dateTime);
  }

  Future<void> fetchPetApplicants() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.petId}/get/applications'; // Replace with your actual URL

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Use the token for authentication
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Assuming the data is a list of applicants
      setState(() {
        petApplicants =
            (data as List).map((app) => _mapApplicant(app)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("Failed to load pet applicants: ${response.statusCode}");
    }
  }

  Map<String, dynamic> _mapApplicant(dynamic app) {
    return {
      'pet_name': app['pet_name'],
      'application_id': app['application_id'],
      'first_name': app['first_name'],
      'last_name': app['last_name'],
      'email': app['email'],
      'contact_number': app['contact_number'],
      'address': app['address'],
      'adopter_profile': app['adopter_profile'],
      'adopter_profile_decoded': _decodeBase64Image(app['adopter_profile']),
      'status': app['status'],
      'created_at': formatDateTime(app['created_at']), // Formatted date
    };
  }

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null; // If the string is null or empty, return null
    }
    try {
      final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
      base64String =
          base64String.replaceAll(regex, ''); // Remove any potential prefix
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding Base64 image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // 🔹 Fixed gray drag handle bar
          Container(
            height: 7,
            width: 120,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  petApplicants.isNotEmpty
                      ? '${petApplicants.first['pet_name']}'
                          .toString()
                          .toUpperCase()
                      : '',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    color: Colors.lightBlue, // 🔹 Pet name in light blue
                  ),
                ),
                Text(
                  '${petApplicants.length} applicants',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          Divider(thickness: 1),
          SizedBox(height: 5),
          // 🔹 Scrollable applicant list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : petApplicants.isEmpty
                    ? const Center(child: Text("No applicants yet"))
                    : ListView.builder(
                        itemCount: petApplicants.length,
                        itemBuilder: (context, index) {
                          final applicant = petApplicants[index];

                          final adopterProfile =
                              applicant['adopter_profile_decoded'] != null
                                  ? MemoryImage(
                                      applicant['adopter_profile_decoded'])
                                  : const AssetImage('assets/images/logo.png')
                                      as ImageProvider;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ApplicationDetailsScreen(
                                    applicationId: applicant['application_id'],
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 8),
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
                                      backgroundImage: adopterProfile,
                                    ),
                                  ],
                                ),
                                title: Text(
                                  '${applicant['first_name']} ${applicant['last_name']}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${applicant['contact_number']}',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${applicant['email']}',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${applicant['address']}',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${applicant['created_at']}',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
