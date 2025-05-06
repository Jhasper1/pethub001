import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_bar.dart';
import 'application_details_screen.dart'; // Import the details screen

class ApplicantsScreen extends StatefulWidget {
  final int shelterId;

  const ApplicantsScreen({super.key, required this.shelterId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  String selectedTab = 'Pending';
  final List<String> tabs =
      ['Pending', 'Approved', 'Completed', 'Rejected'].toList();
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = false;

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

      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          final updatedApplicants =
              data.map((app) => _mapApplicant(app)).toList();
          setState(() {
            applicants = updatedApplicants;
            isLoading = false;
          });
        } else if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            final applicationList = data['data'] as List;
            final updatedApplicants =
                applicationList.map((app) => _mapApplicant(app)).toList();
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
        } else {
          setState(() {
            applicants = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load applicants')),
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
    return {
      'application_id': app['application_id'],
      'first_name': app['first_name'],
      'last_name': app['last_name'],
      'adopter_profile': app['adopter_profile'],
      'pet_name': app['pet_name'],
      'status': app['status'],
      'adopter_profile_decoded': _decodeBase64Image(app['adopter_profile']),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: tabs.map((tab) {
                    final isSelected = tab == selectedTab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () => onTabSelected(tab),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.lightBlue
                              : Colors.grey.shade200,
                          foregroundColor:
                              isSelected ? Colors.white : Colors.black,
                        ),
                        child: Text(tab),
                      ),
                    );
                  }).toList(),
                ),
              ),
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundImage: applicant[
                                                  'adopter_profile_decoded'] !=
                                              null
                                          ? MemoryImage(applicant[
                                              'adopter_profile_decoded'])
                                          : AssetImage(
                                                  'assets/default_avatar.png')
                                              as ImageProvider,
                                    ),
                                    title: Text(
                                        '${applicant['first_name']} ${applicant['last_name']}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        'Chosen Pet: ${applicant['pet_name']}',
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
