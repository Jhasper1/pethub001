import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'pet_clicked.dart';

class ShelterDetailsScreen extends StatefulWidget {
  final String shelterId;

  const ShelterDetailsScreen({required this.shelterId, Key? key}) : super(key: key);

  @override
  State<ShelterDetailsScreen> createState() => _ShelterDetailsScreenState();
}

class _ShelterDetailsScreenState extends State<ShelterDetailsScreen> {
  Map<String, dynamic>? shelterData;
  List<dynamic> pets = [];
  bool isLoading = true;
  bool showPets = true;

  @override
  void initState() {
    super.initState();
    fetchShelterData();
  }

  Future<void> fetchShelterData() async {
    final response = await http.get(
      Uri.parse('http://YOUR_LOCALHOST_OR_DEPLOYED_URL/shelters/${widget.shelterId}'),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        shelterData = responseData['data']['shelter'];
        pets = responseData['data']['pets'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load shelter data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (shelterData == null) {
      return const Scaffold(body: Center(child: Text('Failed to load data')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Shelter Details")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (shelterData!['shelter_cover'] != null)
              CachedNetworkImage(
                imageUrl: shelterData!['shelter_cover'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            const SizedBox(height: 8),
            if (shelterData!['shelter_profile'] != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: CachedNetworkImageProvider(shelterData!['shelter_profile']),
              ),
            const SizedBox(height: 8),
            Text(
              shelterData!['shelter_name'] ?? 'No name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("📍 ${shelterData!['shelter_address'] ?? 'No address'}"),
            Text("📧 ${shelterData!['shelter_email'] ?? 'No email'}"),
            Text("📞 ${shelterData!['shelter_number'] ?? 'No phone number'}"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => showPets = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showPets ? Colors.blue : Colors.grey,
                  ),
                  child: const Text("Pets"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(() => showPets = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !showPets ? Colors.blue : Colors.grey,
                  ),
                  child: const Text("Adoption Policy"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (showPets)
              ...pets.map((pet) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailsScreen(petId: pet['pet_id'].toString(),petData: pet,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: pet['pet_image'] != null
                        ? CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(pet['pet_image']),
                    )
                        : const CircleAvatar(child: Icon(Icons.pets)),
                    title: Text(pet['pet_name'] ?? 'Unnamed Pet'),
                    subtitle: Text(pet['pet_type'] ?? 'Unknown type'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                ),
              )).toList(),
            if (!showPets)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  shelterData!['adoption_policy'] ?? 'No adoption policy provided',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}