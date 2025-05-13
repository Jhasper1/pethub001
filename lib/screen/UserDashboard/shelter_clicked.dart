import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pet_clicked.dart';

class ShelterDetailsScreen extends StatefulWidget {
  final int shelterId;
  final int adopterId; // Default value, can be changed later

  const ShelterDetailsScreen(
      {super.key, required this.shelterId, required this.adopterId});

  @override
  State<ShelterDetailsScreen> createState() => _ShelterDetailsScreenState();
}

class _ShelterDetailsScreenState extends State<ShelterDetailsScreen> {
  Map<String, dynamic>? shelter;
  List<dynamic> pets = [];
  bool isLoading = true;
  String selectedTab = 'pets';

  @override
  void initState() {
    super.initState();
    fetchShelterData();
  }

  Future<void> fetchShelterData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        Uri.parse('http://127.0.0.1:5566/api/user/${widget.shelterId}/pet');

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Check if the response contains a "data" field
        if (decoded['data'] != null) {
          final data = decoded['data'] as Map<String, dynamic>;
          final shelterRaw = data['shelter'];
          final petsRaw = data['pets'];

          setState(() {
            shelter = Map<String, dynamic>.from(shelterRaw);
            pets = List<Map<String, dynamic>>.from(
              (petsRaw as List).map((e) => Map<String, dynamic>.from(e)),
            );
            isLoading = false;
          });
        } else {
          print("No data found in response: ${decoded['message']}");
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("Request failed: ${response.statusCode} - ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error during request: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Uint8List? decodeBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }

  Widget _buildShelterInfo() {
    if (shelter == null) return const Text("Shelter data not available");

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                image: shelter!['sheltermedia']['shelter_cover'] != null
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(
                            shelter!['sheltermedia']['shelter_cover'])),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[300],
              ),
            ),
            Positioned(
              top: 120,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  image: shelter!['sheltermedia']['shelter_profile'] != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(
                              shelter!['sheltermedia']['shelter_profile'])),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                shelter!['shelter_name'] ?? 'N/A',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(shelter!['shelter_address'] ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 4),
                  Text(shelter!['shelter_contact'] ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, size: 16),
                  const SizedBox(width: 4),
                  Text(shelter!['shelter_email'] ?? 'N/A'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetList() {
    if (pets.isEmpty) return const Text("No pets available");

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final pet = pets[index] as Map<String, dynamic>;
        final base64Image = pet['petmedia']['pet_image1'];
        final petName = pet['pet_name'] ?? 'Unnamed';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserPetDetailsScreen(
                  petId: pet['pet_id'],
                  adopterId: widget.adopterId,
                  shelterId: widget.shelterId,
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: base64Image != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(base64Image)),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Text(
                    petName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shelter Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShelterInfo(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedTab = 'pets';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedTab == 'pets'
                                ? Colors.blue
                                : Colors.grey[300],
                            foregroundColor: selectedTab == 'pets'
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: const Text("Pets"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedTab = 'policy';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedTab == 'policy'
                                ? Colors.blue
                                : Colors.grey[300],
                            foregroundColor: selectedTab == 'policy'
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: const Text("Adoption Policy"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedTab == 'pets') ...[
                    const Text(
                      "Available Pets",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildPetList(),
                  ] else ...[
                    const Text(
                      "Adoption Policy",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shelter?['adoption_policy'] ??
                          "No policy provided by the shelter.",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
