import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_bar.dart'; // Import the updated BottomNavigationBar widget

class HomeScreen extends StatefulWidget {
  final int shelterId;
  const HomeScreen({super.key, required this.shelterId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class PetStatusCount {
  final int available;
  final int pending;
  final int adopted;

  PetStatusCount(
      {required this.available, required this.pending, required this.adopted});

  factory PetStatusCount.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PetStatusCount(
      available: data['available'],
      pending: data['pending'],
      adopted: data['adopted'],
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  PetStatusCount? _petCounts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPetCounts(widget.shelterId).then((counts) {
      setState(() {
        _petCounts = counts;
        _isLoading = false;
      });
    });
  }
Future<PetStatusCount?> fetchPetCounts(int shelterId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final url = 'http://127.0.0.1:5566/api/shelter/$shelterId/petcount';

  try {
    final response = await http.get(Uri.parse(url), 
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      return PetStatusCount.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to load pet counts: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print("Error fetching pet counts: $e");
    return null;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      'PetHub',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
            // const SizedBox(height: 20),
            // Text(
            //   'Welcome, Shelter ID: ${widget.shelterId}',
            //   style: GoogleFonts.poppins(
            //     fontSize: 16,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'What are you planning to do today?',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    onPressed: () {
                      // Navigate to add pet screen
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBox(
                          "Available", _petCounts!.available, Colors.green),
                      _buildStatusBox(
                          "Pending", _petCounts!.pending, Colors.orange),
                      _buildStatusBox(
                          "Adopted", _petCounts!.adopted, Colors.blue),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
