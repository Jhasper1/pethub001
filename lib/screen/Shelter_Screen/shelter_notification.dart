import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import the Timer class

class ShelterNotificationScreen extends StatefulWidget {
  @override
  _ShelterNotificationScreenState createState() =>
      _ShelterNotificationScreenState();
}

class _ShelterNotificationScreenState extends State<ShelterNotificationScreen> {
  List<dynamic> adoptionRequests = [];
  bool isLoading = false;
  late Timer _timer; // Declare Timer instance

  // Polling function to check for new adoption requests
  Future<void> fetchAdoptionRequests() async {
    setState(() {
      isLoading = true;
    });

    final url = 'http://127.0.0.1:5566/getAdoptionRequests'; // Your backend URL
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for the response structure and handle accordingly
        if (data != null && data['status'] == 'success') {
          setState(() {
            adoptionRequests = data['data'] ?? []; // Ensure no null value is assigned
          });
        } else {
          print("No new adoption requests or invalid response");
        }
      } else {
        throw Exception('Failed to load adoption requests');
      }
    } catch (e) {
      print("Error fetching adoption requests: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch new requests immediately after loading the screen
    fetchAdoptionRequests();

    // Set up periodic fetching every 30 seconds
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchAdoptionRequests();
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Make sure to cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shelter Notifications'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: adoptionRequests.length,
        itemBuilder: (context, index) {
          final request = adoptionRequests[index];
          return Card(
            child: ListTile(
              title: Text('Adoption Request from ${request['adopter_name']}'),
              subtitle: Text('Pet ID: ${request['pet_id']}'),
              trailing: Icon(Icons.notifications, color: Colors.green),
              onTap: () {
                // Show detailed view or handle action when a request is tapped
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("New Adoption Request"),
                    content: Text(
                        'Adopter: ${request['adopter_name']}\nPet ID: ${request['pet_id']}'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
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
