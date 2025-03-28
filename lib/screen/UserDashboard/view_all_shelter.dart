import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewAllShelter extends StatefulWidget {
  @override
  _ViewAllShelterState createState() => _ViewAllShelterState();
}

class _ViewAllShelterState extends State<ViewAllShelter> {
  List shelters = [];

  @override
  void initState() {
    super.initState();
    fetchShelters();
  }

  Future<void> fetchShelters() async {
    final response = await http.get(Uri.parse('http://localhost:8080/shelters'));

    if (response.statusCode == 200) {
      setState(() {
        shelters = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load shelters');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pet Shelters", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[300],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: shelters.length,
        itemBuilder: (context, index) {
          final shelter = shelters[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter['name'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  shelter['address'],
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 5),
                Text(
                  "Contact: ${shelter['phone']}",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
