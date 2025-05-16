import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'application_details_screen.dart'; // Import the details screen

class ApplicantsScreen extends StatefulWidget {
  final int shelterId;

  const ApplicantsScreen({super.key, required this.shelterId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  String selectedSort = 'Newest';
  final List<String> sortOptions = ['Newest', 'Oldest', 'A to Z', 'Z to A'];

  String selectedTab = 'Interview';
  final List<String> tabs =
      ['Interview', 'Passed', 'Adopted', 'Rejected'].toList();
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = false;

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'No date';
    final dateTime = DateTime.parse(rawDate).toLocal();
    final formatter = DateFormat('MMM d, y');
    return formatter.format(dateTime);
  }

  String formatTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return 'No time';
    final time = DateFormat.Hms().parse(rawTime);
    return DateFormat.jm().format(time);
  }

  @override
  void initState() {
    super.initState();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final status = selectedTab.toLowerCase();
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.shelterId}/adoption-applications?status=$status';

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded != null &&
            decoded is Map &&
            decoded.containsKey('data') &&
            decoded['data'] is Map &&
            decoded['data'].containsKey('submissions') &&
            decoded['data']['submissions'] is List) {
          final List applicationList = decoded['data']['submissions'];
          print('Fetched ${applicationList.length} applicants');

          final updatedApplicants =
              applicationList.map((app) => _mapApplicant(app)).toList();

          // Sort the applicants list after mapping
          updatedApplicants.sort((a, b) {
            DateTime dateA =
                DateTime.tryParse(a['created_at']) ?? DateTime(2000);
            DateTime dateB =
                DateTime.tryParse(b['created_at']) ?? DateTime(2000);

            if (selectedSort == 'A to Z') {
              return a['first_name']
                  .toString()
                  .toLowerCase()
                  .compareTo(b['first_name'].toString().toLowerCase());
            } else if (selectedSort == 'Z to A') {
              return b['first_name']
                  .toString()
                  .toLowerCase()
                  .compareTo(a['first_name'].toString().toLowerCase());
            } else if (selectedSort == 'Newest') {
              return dateB.compareTo(dateA);
            } else if (selectedSort == 'Oldest') {
              return dateA.compareTo(dateB);
            } else {
              return 0;
            }
          });

          setState(() {
            applicants = updatedApplicants;
            isLoading = false;
          });
        } else {
          setState(() {
            applicants = [];
            isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          applicants = [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load applicants')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

Map<String, dynamic> _mapApplicant(dynamic app) {
  final adopter = app['adopter'] ?? {};
  final adopterMedia = adopter['adoptermedia'] ?? {};
  final pet = app['pet'] ?? {};
  final scheduleInterview = app['scheduleinterview'];

  bool hasInterview = scheduleInterview != null &&
      scheduleInterview['application_id'] != null;

  return {
    'application_id': app['application_id']?.toString() ?? '',
    'first_name': adopter['first_name']?.toString() ?? '',
    'last_name': adopter['last_name']?.toString() ?? '',
    'adopter_profile': adopterMedia['adopter_profile']?.toString() ?? '',
    'pet_name': pet['pet_name']?.toString() ?? '',
    'status': app['status']?.toString() ?? '',
    'created_at': app['created_at']?.toString() ?? '',
    'has_interview': hasInterview,
    'interview_date': hasInterview
        ? scheduleInterview['interview_date']?.toString()
        : null,
    'interview_time': hasInterview
        ? scheduleInterview['interview_time']?.toString()
        : null,
    'interview_notes': hasInterview
        ? scheduleInterview['interview_notes']?.toString() ?? ''
        : '',
    'adopter_profile_decoded':
        _decodeBase64Image(adopterMedia['adopter_profile']?.toString()),
  };
}

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null; // If the string is null or empty, return null
    }
    try {
      final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
      base64String = base64String.replaceAll(regex, '');
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding Base64 image: $e");
      return null;
    }
  }

  // Function to handle tab selection
  void onTabSelected(String tab) {
    setState(() {
      selectedTab = tab;
    });
    fetchApplicants(); // Re-fetch applicants based on the new status
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Adoption Applications',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchApplicants,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    DropdownButton<String>(
                      value: selectedTab,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedTab = value;
                          });
                          fetchApplicants();
                        }
                      },
                      items: tabs.map((tab) {
                        return DropdownMenuItem(
                          value: tab,
                          child: Text(tab, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 14),
                      icon: const Icon(Icons.arrow_drop_down),
                      underline: Container(height: 2, color: Colors.lightBlue),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedSort,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSort = value;
                          });
                          fetchApplicants();
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
                          color: Colors.black, fontSize: 14),
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
                "Here is the list of applications:",
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : applicants.isEmpty
                      ? Center(
                          child: Text('No applications found.',
                              style: GoogleFonts.poppins()))
                      : ListView.builder(
                          itemCount: applicants.length,
                          itemBuilder: (context, index) {
                            final applicant = applicants[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ApplicationDetailsScreen(
                                      applicationId:
                                          applicant['application_id'],
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        applicant['adopter_profile_decoded'] !=
                                                null
                                            ? MemoryImage(applicant[
                                                'adopter_profile_decoded'])
                                            : const AssetImage(
                                                    'assets/images/logo.png')
                                                as ImageProvider,
                                  ),
                                  title: Text(
                                    '${applicant['first_name']} ${applicant['last_name']}',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text.rich(
                                    TextSpan(
                                      style: GoogleFonts.poppins(fontSize: 12),
                                      children: [
                                        TextSpan(
                                            text:
                                                'Chosen Pet: ${applicant['pet_name']}\n'),
                                        if (applicant['has_interview'] &&
                                            applicant['interview_time'] !=
                                                null &&
                                            applicant['interview_date'] !=
                                                null) ...[
                                          const TextSpan(
                                            text: 'Interview: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text:
                                                '\n${formatTime(applicant['interview_time'])} | ${formatDate(applicant['interview_date'])}\n',
                                          ),
                                          const TextSpan(
                                            text: 'Notes: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                              text:
                                                  '\n${applicant['interview_notes'] ?? ''}'),
                                        ] else ...[
                                          const TextSpan(text: 'No Interview'),
                                        ],
                                      ],
                                    ),
                                  ),
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
