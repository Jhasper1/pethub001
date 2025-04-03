import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/shelter_clicked.dart';

class ShelterScreen extends StatefulWidget {
  @override
  _ShelterScreenState createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  List<dynamic> shelters = []; // List to hold shelter data
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchShelters();
  }

  Future<void> fetchShelters() async {
    final url = Uri.parse("http://127.0.0.1:5566/allshelter"); // API URL

    try {
      final response = await http.get(url).timeout(Duration(seconds: 10)); // Timeout for request

      print("API Response: ${response.body}"); // Log raw API response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Decoded Data: $data"); // Log decoded data

        setState(() {
          // If the response is a list or has a 'shelters' key
          if (data is List) {
            shelters = data;
          } else if (data.containsKey("shelters")) {
            shelters = data["shelters"];
          } else {
            shelters = [];
          }
          print("Shelters List after setState: $shelters"); // Verify if shelters are populated correctly
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load shelters. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching shelters: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Shelters Length: ${shelters.length}"); // Log list length

    return Scaffold(
      appBar: AppBar(title: Text("Shelters"), centerTitle: true),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : shelters.isEmpty
          ? Center(child: Text("No shelters available"))
          : ListView.builder(
        key: UniqueKey(), // Forces UI rebuild on each state change
        itemCount: shelters.length,
        itemBuilder: (context, index) {
          final shelter = shelters[index];
          return Card(
            child: ListTile(
              title: Text(shelter["shelter_name"] ?? "Unknown Shelter",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(shelter["shelter_address"] ?? "No address available"),
              leading: Icon(Icons.home, color: Colors.orange),
              onTap: () {
                // Navigate to Shelter Details Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShelterDetailsPage(shelterId: shelter["shelter_id"]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
