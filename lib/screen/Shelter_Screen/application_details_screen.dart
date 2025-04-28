import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final int applicationId;

  const ApplicationDetailsScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  Map<String, dynamic>? petData;
  Map<String, dynamic>? adopterData;
  Map<String, dynamic>? applicationData;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplicationDetails();
  }

Future<void> fetchApplicationDetails() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final url =
      'http://127.0.0.1:5566/api/shelter/${widget.applicationId}/application-details'; // Change IP if testing on real phone

  try {
    final response = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("API Response: $data");

      final info = data['data']['info'];

      setState(() {
        petData = {
          'pet_name': info['pet']['pet_name'],
          'pet_type': info['pet']['pet_type'],
          'pet_sex': info['pet']['pet_sex'],
          'pet_age': info['pet']['pet_age'],
          'age_type': info['pet']['age_type'],
          'pet_size': info['pet']['pet_size'],
          'pet_descriptions': info['pet']['pet_descriptions'],
          'pet_image1': info['pet']['pet_media'] != null
              ? _decodeBase64Image(info['pet']['pet_media']['pet_image1'])
              : null,
        };

        adopterData = {
          'first_name': info['adopter']['first_name'],
          'last_name': info['adopter']['last_name'],
          'age': info['adopter']['age'],
          'sex': info['adopter']['sex'],
          'address': info['adopter']['address'],
          'contact_number': info['adopter']['contact_number'],
          'email': info['adopter']['email'],
          'occupation': info['adopter']['occupation'],
          'civil_status': info['adopter']['civil_status'],
          'social_media': info['adopter']['social_media'],
          'adopter_profile': info['adopter']['adoptermedia'] != null
              ? _decodeBase64Image(
                  info['adopter']['adoptermedia']['adopter_profile'])
              : null,
        };

        applicationData = {
          'alt_f_name': info['application']?['alt_f_name'] ?? 'No Available Data',
          'alt_l_name': info['application']?['alt_l_name'] ?? 'No Available Data',
          'relationship': info['application']?['relationship'] ?? 'No Available Data',
          'alt_contact_number': info['application']?['alt_contact_number'] ?? 'No Available Data',
          'alt_email': info['application']?['alt_email'] ?? 'No Available Data',
          'pet_type': info['application']?['pet_type'] ?? 'No Available Data',
          'shelter_animal': info['application']?['shelter_animal'] ?? 'No Available Data',
          'ideal_pet_description': info['application']?['ideal_pet_description'] ?? 'No Available Data',
          'housing_situation': info['application']?['housing_situation'] ?? 'No Available Data',
          'pets_at_home': info['application']?['pets_at_home'] ?? 'No Available Data',
          'allergies': info['application']?['allergies'] ?? 'No Available Data',
          'family_support': info['application']?['family_support'] ?? 'No Available Data',
          'past_pets': info['application']?['past_pets'] ?? 'No Available Data',
          'interview_setting': info['application']?['interview_setting'] ?? 'No Available Data',
          'valid_id': _decodeBase64Image(info['application']?['valid_id'] ?? ''),
          'alt_valid_id': _decodeBase64Image(info['application']?['alt_valid_id'] ?? ''),
        };

        isLoading = false;
      });

      print('Application Data: $applicationData');
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to fetch data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching details: $e');
    setState(() {
      isLoading = false;
    });
  }
}


  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    try {
      final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
      base64String = base64String.replaceAll(regex, '');
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding Base64 image: $e");
      return null;
    }
  }

  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.isNotEmpty == true ? value! : 'No Available Data',
              style: GoogleFonts.poppins(),
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
          title: Text('Application Details ID: ${widget.applicationId}')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (petData == null && adopterData == null)
              ? Center(
                  child: Text('No data found', style: GoogleFonts.poppins()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Pet Info Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: petData!['pet_image1'] != null
                                ? MemoryImage(petData!['pet_image1']!)
                                : AssetImage('assets/images/logo.png')
                                    as ImageProvider,
                          ),
                          title: Text('${petData!['pet_name']}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text('Pet Type: ${petData!['pet_type']} ',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Adopter Info Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 75,
                                      backgroundImage: adopterData![
                                                  'adopter_profile'] !=
                                              null
                                          ? MemoryImage(
                                              adopterData!['adopter_profile']!)
                                          : AssetImage('assets/images/logo.png')
                                              as ImageProvider,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${adopterData!['first_name']} ${adopterData!['last_name']}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Divider(thickness: 2),
                              const SizedBox(height: 10),
                              Text('Adopter Details',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              _infoRow('Age', '${adopterData!['age']}'),
                              _infoRow('Sex', adopterData!['sex']),
                              _infoRow('Address', adopterData!['address']),
                              _infoRow('Contact Number',
                                  adopterData!['contact_number']),
                              _infoRow('Email', adopterData!['email']),
                              _infoRow(
                                  'Occupation', adopterData!['occupation']),
                              _infoRow(
                                  'Civil Status', adopterData!['civil_status']),
                              _infoRow(
                                  'Social Media', adopterData!['social_media']),
                            ],
                          ),
                        ),
                      ),
                      if (applicationData != null) ...[
                        SizedBox(height: 20),

                        // Application Info Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    'Additional Application Info',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _infoRow(
                                    'Alternative First Name',
                                    applicationData?['alt_f_name'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Alternative Last Name',
                                    applicationData?['alt_l_name'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Relationship',
                                    applicationData?['relationship'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Alt Contact Number',
                                    applicationData?['alt_contact_number'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Alt Email',
                                    applicationData?['alt_email'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Pet Type Interested',
                                    applicationData?['pet_type'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Shelter Animal',
                                    applicationData?['shelter_animal'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Ideal Pet Description',
                                    applicationData?['ideal_pet_description'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Housing Situation',
                                    applicationData?['housing_situation'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Pets At Home',
                                    applicationData?['pets_at_home'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Allergies',
                                    applicationData?['allergies'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Family Support',
                                    applicationData?['family_support'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Past Pets',
                                    applicationData?['past_pets'] ??
                                        'No Available Data'),
                                _infoRow(
                                    'Interview Setting',
                                    applicationData?['interview_setting'] ??
                                        'No Available Data'),
                                const SizedBox(height: 10),
                                Divider(),
                                Text('Valid IDs',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Text('Adopter ID',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12)),
                                        const SizedBox(height: 8),
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage: applicationData?[
                                                      'valid_id'] !=
                                                  null
                                              ? MemoryImage(
                                                  applicationData!['valid_id']!)
                                              : AssetImage(
                                                      'assets/images/logo.png')
                                                  as ImageProvider,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text('Alt Contact ID',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12)),
                                        const SizedBox(height: 8),
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage: applicationData?[
                                                      'alt_valid_id'] !=
                                                  null
                                              ? MemoryImage(applicationData![
                                                  'alt_valid_id']!)
                                              : AssetImage(
                                                      'assets/images/logo.png')
                                                  as ImageProvider,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
    );
  }
}
