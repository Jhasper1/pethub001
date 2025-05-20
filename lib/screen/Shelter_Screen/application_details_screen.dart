import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet_info_screen.dart';
import 'pending_adoption_screen.dart';

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
  bool isExpanded = false;
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
            'shelter_id': info['shelter_id'] ?? 'No Available Data',
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
            'status': info?['status'],
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

  Future<void> updateApplicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final url =
          'http://127.0.0.1:5566/api/shelter/approve-application/${widget.applicationId}';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Application status updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update application")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Adoption Details',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
      ),
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
                          color: const Color.fromARGB(255, 239, 250, 255),
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
                          color: const Color.fromARGB(255, 239, 250, 255),
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
                                                    width: 250,
                                                    height: 150,
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
                                                Text('Adopter ID',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 12)),
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
                                                            width: 250,
                                                            height: 150,
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
                                                        const SizedBox(
                                                            height: 8),
                                                        Text('Alt Contact ID',
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontSize:
                                                                        12)),
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
                          color: const Color.fromARGB(255, 239, 250, 255),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isExpanded = !isExpanded;
                                  });
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "House Photos",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                firstChild: const SizedBox.shrink(),
                                secondChild: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 8,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.9,
                                  ),
                                  itemBuilder: (context, index) {
                                    final imageKey = 'home_image_${index + 1}';
                                    final imageBytes =
                                        applicationData?[imageKey];

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
                                          Text(
                                            homeImageLabels[index],
                                            style: GoogleFonts.poppins(
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 5),
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
                                                      : const AssetImage(
                                                              'assets/images/noimage2.webp')
                                                          as ImageProvider,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
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
            applicationData?['status'] == "pending" ||
                    applicationData?['status'] == "interview" ||
                    applicationData?['status'] == "passed"
                ? Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        alignment: Alignment.center, // Center the text
                      ),
                      onPressed: () {
                        InterviewRejectHelper.showRejectModal(
                            context,
                            widget.applicationId,
                            applicationData?['shelter_id']);
                      },
                      child: Text('Reject',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(width: 10),
            applicationData?['status'] == 'pending'
                ? Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        alignment: Alignment.center, // Center the text
                      ),
                      onPressed: () {
                        InterviewRejectHelper.showInterviewDateModal(
                            context, widget.applicationId);
                      },
                      child: Text('Set Interview Date',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  )
                : const SizedBox.shrink(),
            applicationData?['status'] == 'interview' ||
                    applicationData?['status'] == 'passed'
                ? Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        alignment: Alignment.center,
                      ),
                      onPressed: () {
                        String status = applicationData?['status'] ?? '';
                        String title = status == 'interview'
                            ? 'Approve Application'
                            : 'Complete Adoption';
                        String content = status == 'interview'
                            ? 'Are you sure you want to approve this application? \n\n'
                                'Note: Mark as Passed if the adopter passed the interview.'
                            : 'Are you sure you want to mark this adoption as complete? \n\n'
                                'Note: Mark as complete if the adopter will pick up the pet.';

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(title),
                              content: Text(content),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Confirm'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    updateApplicationStatus();
                                    setState(() {});
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        applicationData?['status'] == 'interview'
                            ? 'Approve'
                            : 'Complete',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class InterviewRejectHelper {
  static Future<void> showInterviewDateModal(
      BuildContext context, int applicationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final appInfoResponse = await http.get(
      Uri.parse(
          "http://127.0.0.1:5566/api/shelter/$applicationId/application-details"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (appInfoResponse.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch application data")),
      );
      return;
    }

    final responseBody = jsonDecode(appInfoResponse.body);
    print("FULL RESPONSE: $responseBody");

    if (responseBody['data'] == null || responseBody['data']['info'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No application info found")),
      );
      return;
    }

    final interviewSetting = responseBody['data']['info']['interview_setting'];

    TextEditingController dateController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    TextEditingController notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isConfirmEnabled = dateController.text.isNotEmpty &&
                timeController.text.isNotEmpty;

            return AlertDialog(
              title: Text("Set Interview Schedule"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Text("Interview Setting: $interviewSetting"),
                    SizedBox(height: 10),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      onTap: () async {
                        DateTime now = DateTime.now();
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          String formattedDate =
                              DateFormat('MMMM d, yyyy').format(pickedDate);
                          dateController.text = formattedDate;
                          setState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Date (e.g. January 24, 2025)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context)
                                  .copyWith(alwaysUse24HourFormat: false),
                              child: child ?? const SizedBox(),
                            );
                          },
                        );
                        if (pickedTime != null) {
                          final hour = pickedTime.hourOfPeriod == 0
                              ? 12
                              : pickedTime.hourOfPeriod;
                          final period =
                              pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
                          timeController.text =
                              "${hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00 $period";
                          setState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Time (HH:MM:SS AM/PM)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Reminder (optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: isConfirmEnabled
                      ? () async {
                          String date = dateController.text.trim();
                          String time = timeController.text.trim();
                          String notes = notesController.text.trim();

                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('auth_token');
                          final url = Uri.parse(
                              "http://127.0.0.1:5566/api/shelter/application/$applicationId/set-interview-date");

                          final response = await http.post(
                            url,
                            headers: {
                              "Content-Type": "application/json",
                              "Authorization": "Bearer $token",
                            },
                            body: jsonEncode({
                              "interview_date": date,
                              "interview_time": time,
                              "interview_notes": notes,
                            }),
                          );

                          Navigator.pop(context); // Close dialog

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Interview scheduled successfully")),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PendingApplicantsScreen(
                                    shelterId: responseBody['data']['info']
                                        ['shelter_id']),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Failed to schedule interview")),
                            );
                          }
                        }
                      : null,
                  child: Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================== REJECT MODAL ==================
  static Future<void> showRejectModal(
      BuildContext context, int applicationId, int? shelterId) async {
    List<String> allReasons = [
      "Incomplete documents",
      "Home not suitable",
      "Did not attend interview",
      "Other pets not vaccinated",
      "No stable income",
    ];

    List<String> selectedReasons = [];

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text("Reject Application"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: allReasons.map((reason) {
                  return CheckboxListTile(
                    title: Text(reason),
                    value: selectedReasons.contains(reason),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedReasons.add(reason);
                        } else {
                          selectedReasons.remove(reason);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: selectedReasons.isNotEmpty
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text("Confirm"),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      // Ask for final confirmation
      bool finalConfirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Rejection"),
          content: Text(
              "Are you sure you want to reject this application for the following reason(s)?\n\n${selectedReasons.join(", \n ")}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Yes"),
            ),
          ],
        ),
      );

      if (finalConfirm == true) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        final url = Uri.parse(
            "http://127.0.0.1:5566/api/shelter/reject-application/$applicationId");

        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "reason_for_rejection": selectedReasons,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Application rejected successfully")),
          );

          // Navigate to PendingApplicationScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    PendingApplicantsScreen(shelterId: shelterId ?? 0)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to reject application")),
          );
        }
      }
    }
  }
}
