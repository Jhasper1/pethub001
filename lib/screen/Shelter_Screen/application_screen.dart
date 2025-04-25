import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_bar.dart';

class ApplicantsScreen extends StatefulWidget {
  final int shelterId;

  const ApplicantsScreen({super.key, required this.shelterId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  String selectedTab = 'Pending';
  final List<String> tabs = ['Pending', 'Confirmed', 'Completed', 'Rejected'];
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchApplicants(); // Load initial data
  }

  Future<void> fetchApplicants() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() {
      isLoading = true;
    });

    final status = selectedTab;
    final url =
        'http://127.0.0.1:5566/api/shelter/adoption-applications?shelter_id=${widget.shelterId}&status=$status';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          applicants = data
              .map((app) => {
                    'name':
                        '${app['adopter']['first_name']} ${app['adopter']['last_name']}',
                    'info': 'Pet: ${app['pet']['pet_name']}',
                    'profile': app['adopterprofile']
                        ['adopter_profile'], // this contains base64 string
                  })
              .toList();
        });
      } else {
        print('Failed to fetch applicants: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching applicants: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  void onTabSelected(String tab) {
    setState(() {
      selectedTab = tab;
    });
    fetchApplicants(); // Reload data when tab changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'Adopter Applications',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: applicants.isEmpty
                        ? Center(child: Text('No applicants found.'))
                        : ListView.builder(
                            itemCount: applicants.length,
                            itemBuilder: (context, index) {
                              final applicant = applicants[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage: applicant['adopter_profile'] !=
                                                null &&
                                            applicant['adopter_profile']
                                                .toString()
                                                .isNotEmpty
                                        ? MemoryImage(
                                            base64Decode(applicant['adopter_profile']))
                                        : AssetImage(
                                                'assets/images/logo.png')
                                            as ImageProvider,
                                  ),
                                  title: Text(applicant['name']),
                                  subtitle: Text(applicant['info']),
                                  trailing: Icon(Icons.arrow_forward_ios),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 3,
      ),
    );
  }
}
