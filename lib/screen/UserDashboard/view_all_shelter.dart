import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/shelter_clicked.dart';

class ShelterScreen extends StatefulWidget {
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
    final url = Uri.parse("http://127.0.0.1:5566/allshelter");

    try {
      final response = await http.get(url).timeout(Duration(seconds: 10));

      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Decoded Data: $data");

        setState(() {
          if (data is List) {
            shelters = data;
          } else if (data.containsKey("shelters")) {
            shelters = data["shelters"];
          } else {
            shelters = [];
          }
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

  Widget _buildShelterImage(dynamic shelter) {
    try {
      if (shelter["shelter_profile"] != null && shelter["shelter_profile"].isNotEmpty) {
        final imageBytes = base64Decode(shelter["shelter_profile"]);
        return CircleAvatar(
          radius: 25,
          backgroundImage: MemoryImage(imageBytes),
        );
      }
    } catch (e) {
      print("Error decoding shelter profile image: $e");
    }
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.orange[100],
      child: Icon(Icons.home, color: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shelters"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : shelters.isEmpty
          ? Center(child: Text("No shelters available"))
          : ListView.builder(
        itemCount: shelters.length,
        itemBuilder: (context, index) {
          final shelter = shelters[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: _buildShelterImage(shelter),
              title: Text(
                shelter["shelter_name"] ?? "Unknown Shelter",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shelter["shelter_address"] ?? "No address available"),
                  SizedBox(height: 4),
                ],
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
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