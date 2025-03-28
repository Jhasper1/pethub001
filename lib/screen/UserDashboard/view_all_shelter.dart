import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(ShelterApp());
}

class ShelterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShelterScreen(),
    );
  }
}

class ShelterScreen extends StatefulWidget {
  @override
  _ShelterScreenState createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  List shelters = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchShelters();
  }

  Future<void> fetchShelters() async {
    final url = Uri.parse("http://127.0.0.1:5566/allshelter"); // Update with your actual API URL

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            shelters = data;
            isLoading = false;
          });
        } else if (data is Map && data.containsKey("shelters")) {
          setState(() {
            shelters = data["shelters"];
            isLoading = false;
          });
        } else {
          throw Exception("Unexpected JSON format");
        }
      } else {
        throw Exception("Failed to load shelters. Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching shelters: $e";
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shelters"), centerTitle: true),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : ListView.builder(
        itemCount: shelters.length,
        itemBuilder: (context, index) {
          final shelter = shelters[index];
          return Card(
            child: ListTile(
              title: Text(shelter["shelter_name"], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(shelter["shelter_address"]),
              leading: Icon(Icons.home, color: Colors.orange),
            ),
          );
        },
      ),
    );
  }
}
