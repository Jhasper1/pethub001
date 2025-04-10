import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pet_clicked.dart';

class ShelterDetailsPage extends StatefulWidget {
  final int shelterId;

  const ShelterDetailsPage({Key? key, required this.shelterId}) : super(key: key);

  @override
  _ShelterDetailsPageState createState() => _ShelterDetailsPageState();
}

class _ShelterDetailsPageState extends State<ShelterDetailsPage> {
  Map<String, dynamic>? shelterInfo;
  List<dynamic> pets = [];
  bool isLoading = true;
  bool shelterLoaded = false;
  String errorMessage = "";
  bool _showPets = true; // Default to showing Pets
  Uint8List? _shelterProfileImage;
  Uint8List? _shelterCoverImage;

  @override
  void initState() {
    super.initState();
    fetchShelterDetails();
  }

  Future<void> fetchShelterDetails() async {
    final shelterUrl = Uri.parse("http://127.0.0.1:5566/users/shelters/${widget.shelterId}");
    final petsUrl = Uri.parse("http://127.0.0.1:5566/users/${widget.shelterId}/pets");

    try {
      final shelterResponse = await http.get(shelterUrl);
      if (shelterResponse.statusCode == 200) {
        final shelterData = json.decode(shelterResponse.body);
        setState(() {
          shelterInfo = shelterData["data"]["info"];
          if (shelterData["data"]["shelter_profile"] != null) {
            _shelterProfileImage = base64Decode(shelterData["data"]["shelter_profile"]);
          }
          if (shelterData["data"]["shelter_cover"] != null) {
            _shelterCoverImage = base64Decode(shelterData["data"]["shelter_cover"]);
          }
          shelterLoaded = true;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load shelter details";
          isLoading = false;
        });
        return;
      }

      final petsResponse = await http.get(petsUrl);
      if (petsResponse.statusCode == 200) {
        final petsData = json.decode(petsResponse.body);
        setState(() {
          pets = petsData["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          pets = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Widget _buildPetCard(dynamic pet) {
    Uint8List? petImage;
    if (pet['pet_image1'] != null) {
      petImage = base64Decode(pet['pet_image1']);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetDetailsScreen(petId: pet['pet_id']),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: petImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.memory(petImage, fit: BoxFit.cover),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                pet['pet_name'] ?? 'Unnamed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Adoption Policy",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            shelterInfo?['adoption_policy'] ?? "No policy information available.",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            "Requirements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            shelterInfo?['requirements'] ?? "No specific requirements listed.",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showPets = true;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _showPets ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(25)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pets',
                  style: TextStyle(
                    color: _showPets ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showPets = false;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: !_showPets ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Adoption Policy',
                  style: TextStyle(
                    color: !_showPets ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shelter Details"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : shelterLoaded
          ? Column(
        children: [
          Stack(
            children: [
              Container(
                height: 150,
                decoration: _shelterCoverImage != null
                    ? BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(_shelterCoverImage!),
                    fit: BoxFit.cover,
                  ),
                )
                    : const BoxDecoration(color: Colors.orange),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const SizedBox(height: 90),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        image: _shelterProfileImage != null
                            ? DecorationImage(
                          image: MemoryImage(_shelterProfileImage!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _shelterProfileImage == null
                          ? Icon(Icons.pets, size: 50, color: Colors.grey[600])
                          : null,
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              shelterInfo?['shelter_name'] ?? 'No name available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 10),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  shelterInfo?['shelter_description'] ?? "No description available",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Address
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Address",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  shelterInfo?['shelter_address'] ?? "No address available",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Contact Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Contact Number",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  shelterInfo?['shelter_contact'] ?? "No contact number available",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  shelterInfo?['shelter_email'] ?? "No email available",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          // Toggle Buttons with Animation
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildToggleButtons(),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _showPets
                  ? pets.isEmpty
                  ? Center(child: Text("No pets available"))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: pets.length,
                itemBuilder: (context, index) => _buildPetCard(pets[index]),
              )
                  : _buildPolicyContent(),
            ),
          ),
        ],
      )
          : Center(child: Text(errorMessage)),
    );
  }
}
