import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

class ApplicantsScreen extends StatefulWidget {
  final int shelterId;

  const ApplicantsScreen({super.key, required this.shelterId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  String selectedTab = 'New';

  final List<String> tabs = ['New', 'Confirmed', 'Completed', 'Rejected'];

  final List<Map<String, String>> applicants = [
    {
      'name': 'Mark Erish Ibias',
      'info': 'Age: 25, Location: Manila',
    },
    {
      'name': 'Jane Santos',
      'info': 'Age: 22, Location: Quezon City',
    },
    {
      'name': 'Carlos Dela Cruz',
      'info': 'Age: 30, Location: Cebu',
    },
    {
      'name': 'Anna Lopez',
      'info': 'Age: 27, Location: Davao',
    },
  ];

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
                padding:
                    const EdgeInsets.only(bottom: 12), // Bottom padding here
                child: Row(
                  children: tabs.map((tab) {
                    final isSelected = tab == selectedTab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedTab = tab;
                          });
                        },
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
            Expanded(
              child: ListView.builder(
                itemCount: applicants.length,
                itemBuilder: (context, index) {
                  final applicant = applicants[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.person, size: 32, color: Colors.blue),
                      title: Text(applicant['name']!),
                      subtitle: Text(applicant['info']!),
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
