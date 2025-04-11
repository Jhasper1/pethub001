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
  String errorMessage = "";
  bool _showPets = true;
  Uint8List? _shelterProfileImage;
  Uint8List? _shelterCoverImage;

  @override
  void initState() {
    super.initState();
    fetchShelterDetails();
  }

  Future<void> fetchShelterDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      // Fetch shelter details
      final shelterUrl = Uri.parse("http://127.0.0.1:5566/users/shelters/${widget.shelterId}");
      debugPrint("Fetching shelter: ${shelterUrl.toString()}");

      final shelterResponse = await http.get(shelterUrl);
      debugPrint("Shelter response: ${shelterResponse.statusCode}");

      if (shelterResponse.statusCode == 200) {
        final shelterData = json.decode(shelterResponse.body);
        debugPrint("Shelter data: $shelterData");

        setState(() {
          shelterInfo = shelterData["data"]["info"];
          _shelterProfileImage = _decodeImage(shelterData["data"]["shelter_profile"]);
          _shelterCoverImage = _decodeImage(shelterData["data"]["shelter_cover"]);
        });
      } else {
        throw Exception("Failed to load shelter: ${shelterResponse.statusCode}");
      }

      // Fetch pets
      final petsUrl = Uri.parse("http://127.0.0.1:5566/users/${widget.shelterId}/petinfo");
      debugPrint("Fetching pets: ${petsUrl.toString()}");

      final petsResponse = await http.get(petsUrl);
      debugPrint("Pets response: ${petsResponse.statusCode}");
      debugPrint("Pets body: ${petsResponse.body}");

      if (petsResponse.statusCode == 200) {
        final petsData = json.decode(petsResponse.body);
        debugPrint("Pets data: $petsData");

        setState(() {
          if (petsData["data"] == null) {
            pets = [];
          } else if (petsData["data"] is List) {
            pets = petsData["data"];
          } else if (petsData["data"] is Map) {
            pets = [petsData["data"]]; // Wrap single pet in array
          } else {
            pets = [];
            debugPrint("Unexpected pets data format");
          }
        });
      } else if (petsResponse.statusCode == 404) {
        // Handle case where no pets are found (404)
        setState(() {
          pets = [];
        });
      } else {
        throw Exception("Failed to load pets: ${petsResponse.statusCode}");
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        errorMessage = "Failed to load data. Pull down to refresh.\nError: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Uint8List? _decodeImage(dynamic imageData) {
    if (imageData == null) return null;
    try {
      final imageStr = imageData.toString();
      return base64Decode(imageStr.contains(',')
          ? imageStr.split(',').last
          : imageStr);
    } catch (e) {
      debugPrint("Image decode error: $e");
      return null;
    }
  }

  Widget _buildPetCard(dynamic pet) {
    final petId = pet['pet_id']?.toString() ?? '0';
    final petName = pet['pet_name']?.toString() ?? 'Unnamed';
    final petType = pet['pet_type']?.toString() ?? 'Unknown';

    Uint8List? petImage;
    try {
      petImage = _decodeImage(pet['pet_image1']);
    } catch (e) {
      debugPrint("Error with pet image: $e");
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetDetailsScreen(petId: int.tryParse(petId) ?? 0),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: EdgeInsets.all(8),
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
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    petType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _showPets ? Colors.blue : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => setState(() => _showPets = true),
              child: Text(
                'Pets',
                style: TextStyle(
                  color: _showPets ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: !_showPets ? Colors.blue : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => setState(() => _showPets = false),
              child: Text(
                'Policy',
                style: TextStyle(
                  color: !_showPets ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelterHeader() {
    return Stack(
      children: [
        Container(
          height: 180,
          decoration: _shelterCoverImage != null
              ? BoxDecoration(
            image: DecorationImage(
              image: MemoryImage(_shelterCoverImage!),
              fit: BoxFit.cover,
            ),
          )
              : BoxDecoration(color: Colors.blue[200]),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
                image: _shelterProfileImage != null
                    ? DecorationImage(
                  image: MemoryImage(_shelterProfileImage!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _shelterProfileImage == null
                  ? Icon(Icons.apartment, size: 40, color: Colors.grey[600])
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShelterInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              shelterInfo?['shelter_name'] ?? 'Shelter',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            shelterInfo?['shelter_description'] ?? "No description available",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  shelterInfo?['shelter_address'] ?? "No address available",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                shelterInfo?['shelter_contact'] ?? "No contact available",
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                shelterInfo?['shelter_email'] ?? "No email available",
                style: TextStyle(fontSize: 15),
              ),
            ],
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
          : errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchShelterDetails,
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchShelterDetails,
        child: ListView(
          children: [
            _buildShelterHeader(),
            SizedBox(height: 16),
            _buildShelterInfo(),
            SizedBox(height: 16),
            _buildToggleButtons(),
            _showPets
                ? pets.isEmpty
                ? Container(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pets, size: 50, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No pets available in this shelter",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
                : GridView.builder(
              padding: EdgeInsets.all(16),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: pets.length,
              itemBuilder: (context, index) => _buildPetCard(pets[index]),
            )
                : _buildPolicyContent(),
          ],
        ),
      ),
    );
  }
}