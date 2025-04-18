import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  PetStatusCount({required this.available, required this.pending, required this.adopted});

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
  

  Future<PetStatusCount> fetchPetCounts(int shelterId) async {
  final url = Uri.parse('http://127.0.0.1:5566/shelter/$shelterId/petcount');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return PetStatusCount.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load pet counts');
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
                    const Text(
                      'PetHub',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, Shelter ID: ${widget.shelterId}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                  children: const [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'What are you planning to do today?',
                    style: TextStyle(color: Colors.white70),
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
                      _buildStatusBox("Available", _petCounts!.available, Colors.green),
                      _buildStatusBox("Pending", _petCounts!.pending, Colors.orange),
                      _buildStatusBox("Adopted", _petCounts!.adopted, Colors.blue),
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
              style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
