import 'dart:convert';
import 'dart:typed_data';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/UserDashboard/pet_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final int applicationId;
  final int adopterId;

  const ApplicationDetailsScreen({
    super.key,
    required this.applicationId,
    required this.adopterId,
  });

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  Map<String, dynamic>? petData;
  Map<String, dynamic>? adopterData;
  Map<String, dynamic>? applicationData;
  bool isLoading = true;
  String? applicationStatus;

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

  @override
  void initState() {
    super.initState();
    fetchApplicationData();
  }

  Future<void> fetchApplicationData() async {
    if (widget.adopterId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/applications/adopter/${widget.applicationId}';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          // Extract application status from the `info` object
          final info = data['data']?['info'] ?? {};
          applicationStatus = info['status'] ?? 'No Status Available';

          // Extract pet data
          final pet = info['pet'] ?? {};
          final petMedia = pet['petmedia'] ?? {};
          petData = {
            'pet_id': pet['pet_id']?.toString() ?? 'N/A',
            'shelter_id': pet['shelter_id']?.toString() ?? 'N/A',
            'pet_name': pet['pet_name'] ?? 'No Available Data',
            'pet_type': pet['pet_type'] ?? 'No Available Data',
            'pet_sex': pet['pet_sex'] ?? 'No Available Data',
            'pet_age': pet['pet_age']?.toString() ?? 'No Available Data',
            'age_type': pet['age_type'] ?? 'No Available Data',
            'pet_size': pet['pet_size'] ?? 'No Available Data',
            'pet_descriptions': pet['pet_descriptions'] ?? 'No Available Data',
            'pet_image1': decodeBase64Image(petMedia['pet_image1']),
          };

          // Extract adopter data
          final adopter = info['adopter'] ?? {};
          final adopterMedia = adopter['adoptermedia'] ?? {};
          adopterData = {
            'adopter_id': adopter['adopter_id']?.toString() ?? 'N/A',
            'first_name': adopter['first_name'] ?? 'No Available Data',
            'last_name': adopter['last_name'] ?? 'No Available Data',
            'age': adopter['age']?.toString() ?? 'No Available Data',
            'sex': adopter['sex'] ?? 'No Available Data',
            'address': adopter['address'] ?? 'No Available Data',
            'contact_number': adopter['contact_number'] ?? 'No Available Data',
            'email': adopter['email'] ?? 'No Available Data',
            'occupation': adopter['occupation'] ?? 'No Available Data',
            'civil_status': adopter['civil_status'] ?? 'No Available Data',
            'social_media': adopter['social_media'] ?? 'No Available Data',
            'adopter_profile':
                decodeBase64Image(adopterMedia['adopter_profile']),
          };

          // Extract application data
          final photos = data['data']?['applicationPhotos'] ?? {};
          final homeImages = data['data']?['homeImages'] ?? [];
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
                decodeBase64Image(photos?['adopter_valid_id'] ?? ''),
            'alt_id_type': photos?['alt_id_type'] ?? 'No Available Data',
            'alt_valid_id': decodeBase64Image(photos?['alt_valid_id'] ?? ''),
            'home_image_1': decodeBase64Image(photos?['home_image1'] ?? ''),
            'home_image_2': decodeBase64Image(photos?['home_image2'] ?? ''),
            'home_image_3': decodeBase64Image(photos?['home_image3'] ?? ''),
            'home_image_4': decodeBase64Image(photos?['home_image4'] ?? ''),
            'home_image_5': decodeBase64Image(photos?['home_image5'] ?? ''),
            'home_image_6': decodeBase64Image(photos?['home_image6'] ?? ''),
            'home_image_7': decodeBase64Image(photos?['home_image7'] ?? ''),
            'home_image_8': decodeBase64Image(photos?['home_image8'] ?? ''),
          };

          for (var image in homeImages) {
            if (image['image_name'] != null && image['image_data'] != null) {
              applicationData![image['image_name']] =
                  decodeBase64Image(image['image_data']);
            }
          }

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
      base64String = base64String.replaceAll(regex, '');
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  Widget infoRow(String title, String? value) {
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

  Widget buildStatusBar() {
    final status = applicationStatus?.toLowerCase() ?? "";

    // Define the steps and their base states
    final steps = [
      {'label': 'Application', 'status': 'application', 'state': 'default'},
      {'label': 'Interview', 'status': 'interview', 'state': 'default'},
      {'label': 'Approval', 'status': 'approved', 'state': 'default'},
      {'label': 'Completed', 'status': 'completed', 'state': 'default'},
    ];

    // Assign visual state: 'completed' (green), 'current' (orange), 'default' (gray), or 'rejected' (red)
    for (int i = 0; i < steps.length; i++) {
      final stepStatus = steps[i]['status'] as String;

      // Reset to default first
      steps[i]['state'] = 'default';

      // Handle all status cases
      if (status == 'pending' || status == 'inqueue') {
        if (stepStatus == 'application') steps[i]['state'] = 'current';
      } else if (status == 'application_reject') {
        if (stepStatus == 'application') steps[i]['state'] = 'rejected';
      } else if (status == 'interview') {
        if (stepStatus == 'application') steps[i]['state'] = 'completed';
        if (stepStatus == 'interview') steps[i]['state'] = 'current';
      } else if (status == 'interview_reject') {
        if (stepStatus == 'application') steps[i]['state'] = 'completed';
        if (stepStatus == 'interview') steps[i]['state'] = 'rejected';
      } else if (status == 'approved') {
        if (stepStatus == 'application' || stepStatus == 'interview') {
          steps[i]['state'] = 'completed';
        }
        if (stepStatus == 'approved') steps[i]['state'] = 'completed';
        if (stepStatus == 'completed') steps[i]['state'] = 'current';
      } else if (status == 'approved_reject') {
        if (stepStatus == 'application' || stepStatus == 'interview') {
          steps[i]['state'] = 'completed';
        }
        if (stepStatus == 'approved') steps[i]['state'] = 'rejected';
      } else if (status == 'completed') {
        steps[i]['state'] = 'completed';
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double avatarSize = constraints.maxWidth < 400 ? 10 : 12;
        final double iconSize = constraints.maxWidth < 400 ? 12 : 14;
        final double lineLength = constraints.maxWidth < 400 ? 20 : 30;
        final double fontSize = constraints.maxWidth < 400 ? 10 : 11;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final isLast = index == steps.length - 1;
                final state = step['state'];

                Color bgColor;
                Widget icon;

                switch (state) {
                  case 'completed':
                    bgColor = Colors.green;
                    icon =
                        Icon(Icons.check, size: iconSize, color: Colors.white);
                    break;
                  case 'current':
                    bgColor = Colors.orange;
                    icon =
                        Icon(Icons.circle, size: iconSize, color: Colors.white);
                    break;
                  case 'rejected':
                    bgColor = Colors.red;
                    icon =
                        Icon(Icons.close, size: iconSize, color: Colors.white);
                    break;
                  default:
                    bgColor = Colors.grey;
                    icon =
                        Icon(Icons.circle, size: iconSize, color: Colors.white);
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: avatarSize,
                          backgroundColor: bgColor,
                          child: icon,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 70,
                          child: Text(
                            step['label'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: fontSize,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: DottedLine(
                          direction: Axis.horizontal,
                          lineLength: lineLength,
                          lineThickness: 1.5,
                          dashColor: Colors.black26,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  void showFullScreenImage(BuildContext context, Uint8List? imageBytes) {
    if (imageBytes == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                  child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              )),
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
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
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
      appBar: AppBar(
        title: const Text('Application Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Move the buildStatusBar here
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: buildStatusBar(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Chosen Pet:",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
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
                            : const AssetImage('assets/images/logo.png')
                                as ImageProvider,
                      ),
                      title: Text(
                        petData!['pet_name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Pet Type: ${petData!['pet_type']}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetDetailsScreen(
                                petData: petData!,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'View',
                          style: GoogleFonts.poppins(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                            tabs: const [
                              Tab(text: 'Adopter Info'),
                              Tab(text: 'Application Info'),
                            ],
                          ),
                          Container(
                            height: 750,
                            padding: const EdgeInsets.all(16.0),
                            child: TabBarView(
                              children: [
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 75,
                                        backgroundImage: adopterData![
                                                    'adopter_profile'] !=
                                                null
                                            ? MemoryImage(adopterData![
                                                'adopter_profile']!)
                                            : const AssetImage(
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
                                      infoRow('Age', adopterData!['age']),
                                      infoRow('Sex', adopterData!['sex']),
                                      infoRow(
                                          'Address', adopterData!['address']),
                                      infoRow('Contact Number',
                                          adopterData!['contact_number']),
                                      infoRow('Email', adopterData!['email']),
                                      infoRow('Occupation',
                                          adopterData!['occupation']),
                                      infoRow('Civil Status',
                                          adopterData!['civil_status']),
                                      infoRow('Social Media',
                                          adopterData!['social_media']),
                                      const SizedBox(height: 20),
                                      const Divider(thickness: 2),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Adopter ID',
                                        style:
                                            GoogleFonts.poppins(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      infoRow('ID Type',
                                          applicationData!['adopter_id_type']),
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
                                          width: 300,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(7),
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: applicationData![
                                                          'adopter_valid_id'] !=
                                                      null
                                                  ? MemoryImage(
                                                      applicationData![
                                                          'adopter_valid_id']!)
                                                  : const AssetImage(
                                                          'assets/images/logo.png')
                                                      as ImageProvider,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      infoRow(
                                          'Reason for Adoption',
                                          applicationData![
                                              'reason_for_adoption']),
                                      infoRow(
                                          'Ideal Pet Description',
                                          applicationData![
                                              'ideal_pet_description']),
                                      infoRow(
                                          'Housing Situation',
                                          applicationData![
                                              'housing_situation']),
                                      infoRow('Pets At Home',
                                          applicationData!['pets_at_home']),
                                      infoRow('Allergies',
                                          applicationData!['allergies']),
                                      infoRow('Family Support',
                                          applicationData!['family_support']),
                                      infoRow('Past Pets',
                                          applicationData!['past_pets']),
                                      infoRow(
                                          'Interview Setting',
                                          applicationData![
                                              'interview_setting']),
                                      const SizedBox(height: 10),
                                      const Divider(),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Secondary Contact Information",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      infoRow('Full Name',
                                          '${applicationData!['alt_f_name']} ${applicationData!['alt_l_name']}'),
                                      infoRow('Relationship',
                                          applicationData!['relationship']),
                                      infoRow(
                                          'Contact Number',
                                          applicationData![
                                              'alt_contact_number']),
                                      infoRow('Email',
                                          applicationData!['alt_email']),
                                      Text(
                                        'Alt ID',
                                        style:
                                            GoogleFonts.poppins(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      infoRow('ID Type',
                                          applicationData!['alt_id_type']),
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
                                          width: 300,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(7),
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: applicationData![
                                                          'alt_valid_id'] !=
                                                      null
                                                  ? MemoryImage(
                                                      applicationData![
                                                          'alt_valid_id']!)
                                                  : const AssetImage(
                                                          'assets/images/logo.png')
                                                      as ImageProvider,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
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
                          const SizedBox(height: 10),
                          GridView.builder(
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
                              final imageBytes = applicationData?[imageKey];

                              return GestureDetector(
                                onTap: () {
                                  if (imageBytes != null) {
                                    showFullScreenImage(context, imageBytes);
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                : const AssetImage(
                                                        'assets/images/logo.png')
                                                    as ImageProvider,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      homeImageLabels[index],
                                      style: GoogleFonts.poppins(fontSize: 12),
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
    );
  }
}
