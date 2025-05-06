import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/shelter_clicked.dart';

class ShelterScreen extends StatefulWidget {
  final int adopterId;
  const ShelterScreen({super.key, required this.adopterId});

  @override
  _ShelterScreenState createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  List<dynamic> shelters = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchShelters();
  }

  Future<void> fetchShelters() async {
    final url = Uri.parse(
        "http://127.0.0.1:5566/all/shelter"); // Updated for Android emulator

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          if (data is List) {
            shelters = data;
          } else if (data is Map && data['data'] is List) {
            shelters = data['data'];
          } else {
            shelters = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              "Failed to load shelters. Status code: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching shelters: $e";
        isLoading = false;
      });
    }
  }

  Widget _buildShelterImage(dynamic shelter) {
    try {
      if (shelter["shelter_profile"] != null &&
          shelter["shelter_profile"].isNotEmpty) {
        final imageBytes = base64Decode(shelter["shelter_profile"]);
        return CircleAvatar(
          radius: 28,
          backgroundImage: MemoryImage(imageBytes),
        );
      }
    } catch (e) {
      print("Error decoding shelter profile image: $e");
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue.shade100,
      child: Icon(Icons.home, color: Colors.blue.shade700, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Available Shelters"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : shelters.isEmpty
                  ? Center(
                      child: Text(
                        "No shelters available",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: shelters.length,
                      itemBuilder: (context, index) {
                        final shelter = shelters[index];
                        return Card(
                          color: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.blue.shade100,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShelterDetailsScreen(
                                    shelterId: shelter["shelter_id"],
                                    adopterId: widget.adopterId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildShelterImage(shelter),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shelter["shelter_name"] ??
                                              "Unknown Shelter",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          shelter["shelter_address"] ??
                                              "No address available",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      color: Colors.blue.shade300),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

