import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pet_info_screen.dart';

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

  final List<String> homeImageLabels = [
    'Front House',
    'Living Room',
    'Kitchen',
    'Bedroom',
    'Bathroom',
    'Backyard',
    'Pet Area',
    'Whole House'
  ];

  Future<void> fetchApplicationDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.applicationId}/application-details';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        final info = data['data']['info'];
        final photos = data['data']['applicationPhotos'];

        setState(() {
          petData = {
            'pet_id': info['pet']['pet_id'],
            'shelter_id': info['pet']['shelter_id'],
            'pet_name': info['pet']['pet_name'] ?? 'No Available Data',
            'pet_type': info['pet']['pet_type'] ?? 'No Available Data',
            'pet_sex': info['pet']['pet_sex'] ?? 'No Available Data',
            'pet_age': info['pet']['pet_age'] ?? 'No Available Data',
            'age_type': info['pet']['age_type'] ?? 'No Available Data',
            'pet_size': info['pet']['pet_size'] ?? 'No Available Data',
            'pet_descriptions':
                info['pet']['pet_descriptions'] ?? 'No Available Data',
            'pet_image1': info['pet']['petmedia'] != null
                ? _decodeBase64Image(info['pet']['petmedia']['pet_image1'])
                : null,
          };

          adopterData = {
            'first_name': info['adopter']['first_name'] ?? 'No Available Data',
            'last_name': info['adopter']['last_name'] ?? 'No Available Data',
            'age': info['adopter']['age'] ?? 'No Available Data',
            'sex': info['adopter']['sex'] ?? 'No Available Data',
            'address': info['adopter']['address'] ?? 'No Available Data',
            'contact_number':
                info['adopter']['contact_number'] ?? 'No Available Data',
            'email': info['adopter']['email'] ?? 'No Available Data',
            'occupation': info['adopter']['occupation'] ?? 'No Available Data',
            'civil_status':
                info['adopter']['civil_status'] ?? 'No Available Data',
            'social_media':
                info['adopter']['social_media'] ?? 'No Available Data',
            'adopter_profile': info['adopter']['adoptermedia'] != null
                ? _decodeBase64Image(
                    info['adopter']['adoptermedia']['adopter_profile'])
                : null,
          };

          applicationData = {
            'alt_f_name': info?['alt_f_name'] ?? 'No Available Data',
            'alt_l_name': info?['alt_l_name'] ?? 'No Available Data',
            'relationship': info?['relationship'] ?? 'No Available Data',
            'alt_contact_number':
                info?['alt_contact_number'] ?? 'No Available Data',
            'alt_email': info?['alt_email'] ?? 'No Available Data',
            'reason_for_adoption':
                info?['reason_for_adoption'] ?? 'No Available Data',
            'ideal_pet_description':
                info?['ideal_pet_description'] ?? 'No Available Data',
            'housing_situation':
                info?['housing_situation'] ?? 'No Available Data',
            'pets_at_home': info?['pets_at_home'] ?? 'No Available Data',
            'allergies': info?['allergies'] ?? 'No Available Data',
            'family_support': info?['family_support'] ?? 'No Available Data',
            'past_pets': info?['past_pets'] ?? 'No Available Data',
            'interview_setting':
                info?['interview_setting'] ?? 'No Available Data',
            'adopter_id_type':
                photos?['adopter_id_type'] ?? 'No Available Data',
            'adopter_valid_id':
                _decodeBase64Image(photos?['adopter_valid_id'] ?? ''),
            'alt_id_type': photos?['alt_id_type'] ?? 'No Available Data',
            'alt_valid_id': _decodeBase64Image(photos?['alt_valid_id'] ?? ''),
            'home_image_1': _decodeBase64Image(photos?['home_image1'] ?? ''),
            'home_image_2': _decodeBase64Image(photos?['home_image2'] ?? ''),
            'home_image_3': _decodeBase64Image(photos?['home_image3'] ?? ''),
            'home_image_4': _decodeBase64Image(photos?['home_image4'] ?? ''),
            'home_image_5': _decodeBase64Image(photos?['home_image5'] ?? ''),
            'home_image_6': _decodeBase64Image(photos?['home_image6'] ?? ''),
            'home_image_7': _decodeBase64Image(photos?['home_image7'] ?? ''),
            'home_image_8': _decodeBase64Image(photos?['home_image8'] ?? ''),
          };

          isLoading = false;
        });
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

  void showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Dim background
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(imageBytes),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2F3FD),
      appBar: AppBar(title: Text('Application Details')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (petData == null && adopterData == null)
              ? Center(
                  child: Text('No data found', style: GoogleFonts.poppins()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Chosen Pet:",
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                          trailing: TextButton(
                            onPressed: () {
                              // Navigate to the PetInfoScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PetDetailsScreen(
                                      petId: petData!['pet_id'],
                                      shelterId: petData!['shelter_id']),
                                ),
                              );
                            },
                            child: Text('View',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                padding: const EdgeInsets.all(16.0),
                                labelColor: Colors.black,
                                indicatorColor: Colors.blue,
                                tabs: [
                                  Tab(text: 'Adopter Info'),
                                  Tab(text: 'Application Info'),
                                ],
                              ),
                              Container(
                                height: 750, // Adjust this height as needed
                                padding: const EdgeInsets.all(16.0),
                                child: TabBarView(
                                  children: [
                                    // First tab: Adopter Info
                                    adopterData != null
                                        ? SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                CircleAvatar(
                                                  radius: 75,
                                                  backgroundImage: adopterData![
                                                              'adopter_profile'] !=
                                                          null
                                                      ? MemoryImage(adopterData![
                                                          'adopter_profile']!)
                                                      : AssetImage(
                                                              'assets/images/logo.png')
                                                          as ImageProvider,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  '${adopterData!['first_name']} ${adopterData!['last_name']}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                _infoRow('Age',
                                                    '${adopterData!['age']}'),
                                                _infoRow(
                                                    'Sex', adopterData!['sex']),
                                                _infoRow('Address',
                                                    adopterData!['address']),
                                                _infoRow(
                                                    'Contact Number',
                                                    adopterData![
                                                        'contact_number']),
                                                _infoRow('Email',
                                                    adopterData!['email']),
                                                _infoRow('Occupation',
                                                    adopterData!['occupation']),
                                                _infoRow(
                                                    'Civil Status',
                                                    adopterData![
                                                        'civil_status']),
                                                _infoRow(
                                                    'Social Media',
                                                    adopterData![
                                                        'social_media']),
                                                const SizedBox(height: 20),
                                                Divider(thickness: 2),
                                                const SizedBox(height: 10),
                                                Text('Adopter ID',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 12)),
                                                const SizedBox(height: 8),
                                                _infoRow(
                                                    'ID Type',
                                                    applicationData![
                                                        'adopter_id_type']),
                                                GestureDetector(
                                                  onTap: () {
                                                    if (applicationData![
                                                            'adopter_valid_id'] !=
                                                        null) {
                                                      showFullScreenImage(
                                                          context,
                                                          applicationData![
                                                              'adopter_valid_id']!);
                                                    }
                                                  },
                                                  child: Container(
                                                    width: 150,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7),
                                                      image: DecorationImage(
                                                        fit: BoxFit.cover,
                                                        image: applicationData![
                                                                    'adopter_valid_id'] !=
                                                                null
                                                            ? MemoryImage(
                                                                applicationData![
                                                                    'adopter_valid_id']!)
                                                            : AssetImage(
                                                                    'assets/images/logo.png')
                                                                as ImageProvider,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Center(
                                            child:
                                                Text('No adopter data found')),

                                    // Second tab: Application Info
                                    applicationData != null
                                        ? SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _infoRow(
                                                    'Reason for Adoption',
                                                    applicationData?[
                                                            'reason_for_adoption'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Ideal Pet Description',
                                                    applicationData?[
                                                            'ideal_pet_description'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Housing Situation',
                                                    applicationData?[
                                                            'housing_situation'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Pets At Home',
                                                    applicationData?[
                                                            'pets_at_home'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Allergies',
                                                    applicationData?[
                                                            'allergies'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Family Support',
                                                    applicationData?[
                                                            'family_support'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Past Pets',
                                                    applicationData?[
                                                            'past_pets'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Interview Setting',
                                                    applicationData?[
                                                            'interview_setting'] ??
                                                        'No Data'),
                                                const SizedBox(height: 10),
                                                Divider(),
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    "Secondary Contact Infomation",
                                                    style: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                _infoRow('Full Name',
                                                    '${applicationData!['alt_f_name']} ${applicationData!['alt_l_name']}'),
                                                _infoRow(
                                                    'Relationship',
                                                    applicationData?[
                                                            'relationship'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Contact Number',
                                                    applicationData?[
                                                            'alt_contact_number'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'Email',
                                                    applicationData?[
                                                            'alt_email'] ??
                                                        'No Data'),
                                                _infoRow(
                                                    'ALT ID Type',
                                                    applicationData?[
                                                            'alt_id_type'] ??
                                                        'No Data'),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Text('Alt Contact ID',
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontSize:
                                                                        12)),
                                                        const SizedBox(
                                                            height: 8),
                                                        GestureDetector(
                                                          onTap: () {
                                                            if (applicationData![
                                                                    'alt_valid_id'] !=
                                                                null) {
                                                              showFullScreenImage(
                                                                  context,
                                                                  applicationData![
                                                                      'alt_valid_id']!);
                                                            }
                                                          },
                                                          child: Container(
                                                            width: 150,
                                                            height: 100,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          7),
                                                              image:
                                                                  DecorationImage(
                                                                fit: BoxFit
                                                                    .cover,
                                                                image: applicationData![
                                                                            'alt_valid_id'] !=
                                                                        null
                                                                    ? MemoryImage(
                                                                        applicationData![
                                                                            'alt_valid_id']!)
                                                                    : AssetImage(
                                                                            'assets/images/logo.png')
                                                                        as ImageProvider,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                                'No application data found')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Home Images",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: 8,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.9,
                                ),
                                itemBuilder: (context, index) {
                                  final imageKey = 'home_image_${index + 1}';
                                  final imageBytes = applicationData?[imageKey];

                                  return GestureDetector(
                                    onTap: () {
                                      if (imageBytes != null) {
                                        showFullScreenImage(
                                            context, imageBytes);
                                      }
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image: imageBytes != null
                                                    ? MemoryImage(imageBytes)
                                                    : AssetImage(
                                                            'assets/images/logo.png')
                                                        as ImageProvider,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          homeImageLabels[index],
                                          style:
                                              GoogleFonts.poppins(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  print("Application Rejected");
                },
                child: Text('Reject',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  print("Application Approved");
                },
                child: Text('Approve',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
