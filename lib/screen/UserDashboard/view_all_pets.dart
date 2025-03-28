import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(ViewAllPets());
}

class ViewAllPets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SearchResultsPage(),
    );
  }
}

class SearchResultsPage extends StatefulWidget {
  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  String selectedCategory = "Cats";  // Default category
  List<dynamic> pets = [];

  @override
  void initState() {
    super.initState();
    fetchPets();
  }

  Future<void> fetchPets() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/pets'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          pets = data;
        });
      } else {
        print("Failed to load pets. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching pets: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredPets =
    pets.where((pet) => pet['category'] == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              print("No previous page found!");
            }
          },
        ),
        title: Text('Pets', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryFilters(),
          Expanded(child: _buildPetList(filteredPets)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton("Dogs"),
          _buildFilterButton("Cats"),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String category) {
    bool isSelected = selectedCategory == category;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = category;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.pets, size: 16, color: isSelected ? Colors.white : Colors.black),
          SizedBox(width: 5),
          Text(category),
        ],
      ),
    );
  }

  Widget _buildPetList(List<dynamic> pets) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: pets.isEmpty
          ? Center(child: Text("No pets found in this category"))
          : ListView.builder(
        itemCount: pets.length,
        itemBuilder: (context, index) {
          return _buildPetCard(pets[index]);
        },
      ),
    );
  }

  Widget _buildPetCard(dynamic pet) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pet["name"] ?? "Unknown Name",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 4),
            Text(
              "${pet["breed"] ?? "Unknown Breed"} • ${pet["distance"] ?? "N/A"} km away",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              "Category: ${pet["category"] ?? "Uncategorized"}",
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
