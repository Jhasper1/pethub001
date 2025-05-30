import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserEditProfileScreen extends StatefulWidget {
  final int adopterId;

  const UserEditProfileScreen({super.key, required this.adopterId});

  @override
  _UserEditProfileScreenState createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  Map<String, dynamic>? adopterInfo;
  bool isLoading = true;

  XFile? profileImageFile;
  Uint8List? profileImageBytes;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController civilStatusController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();

  Future<void> pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (type == 'adopter_profile') {
          profileImageFile = pickedFile;
          profileImageBytes = bytes;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAdopterInfo();
  }

  Future<void> fetchAdopterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final String apiUrl = 'http://127.0.0.1:5566/api/user/${widget.adopterId}';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        print("Full response body: $body"); // Debugging

        if (body is Map<String, dynamic> && body['data'] != null) {
          final data = body['data'];

          setState(() {
            adopterInfo = data;

            // Initialize controllers with current values
            firstNameController.text = adopterInfo!['first_name'] ?? '';
            lastNameController.text = adopterInfo!['last_name'] ?? '';
            addressController.text = adopterInfo!['address'] ?? '';
            contactController.text =
                adopterInfo!['contact_number']?.toString() ?? '';
            emailController.text = adopterInfo!['email'] ?? '';
            occupationController.text = adopterInfo!['occupation'] ?? '';
            civilStatusController.text = adopterInfo!['civil_status'] ?? '';
            socialMediaController.text = adopterInfo!['social_media'] ?? '';

            // Decode base64-encoded images
            if (data['adoptermedia'] != null &&
                data['adoptermedia']['adopter_profile'] != null &&
                data['adoptermedia']['adopter_profile'] is String) {
              profileImageBytes =
                  base64Decode(data['adoptermedia']['adopter_profile']);
            }

            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load adopter details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching adopter details: $e');
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  Future<void> updateAdopterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = 'http://127.0.0.1:5566/api/adopter/${widget.adopterId}/edit';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';

    // Add text form fields
    request.fields['first_name'] = firstNameController.text;
    request.fields['last_name'] = lastNameController.text;
    request.fields['address'] = addressController.text;
    request.fields['contact_number'] = contactController.text;
    request.fields['email'] = emailController.text;
    request.fields['occupation'] = occupationController.text;
    request.fields['civil_status'] = civilStatusController.text;
    request.fields['social_media'] = socialMediaController.text;

    // Add profile image if selected
    if (profileImageFile != null) {
      final bytes = await profileImageFile!.readAsBytes();
      final extension = profileImageFile!.path.split('.').last;
      final fileName = 'profile_${widget.adopterId}.$extension';

      request.files.add(http.MultipartFile.fromBytes(
        'adopter_profile',
        bytes,
        filename: fileName,
        contentType: MediaType('image', extension),
      ));
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        final respStr = await response.stream.bytesToString();
        final decoded = jsonDecode(respStr);
        throw Exception(decoded['message'] ?? 'Update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (adopterInfo == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load profile information')),
      );
    }

    return Scaffold(
       backgroundColor: const Color.fromARGB(255, 239, 250, 255),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        title: Text('Edit Profile',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Card(
              color: Colors.white,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: GestureDetector(
                        onTap: () => pickImage('adopter_profile'),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: profileImageBytes != null
                              ? MemoryImage(profileImageBytes!)
                              : const AssetImage('assets/images/logo.png')
                                  as ImageProvider,
                          child: const Align(
                            alignment: Alignment.bottomRight,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.camera_alt,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'First Name',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textAlign:
                                        TextAlign.left, // or use Align widget
                                  ),
                                  SizedBox(height: 5),
                                  TextFormField(
                                    controller: firstNameController,
                                    decoration:
                                        _inputDecoration('Enter first name'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last Name',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textAlign:
                                        TextAlign.left, // or use Align widget
                                  ),
                                  SizedBox(height: 5),
                                  TextFormField(
                                    controller: lastNameController,
                                    decoration:
                                        _inputDecoration('Enter last name'),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Address',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: addressController,
                          decoration: _inputDecoration('Enter address'),
                        ),
                        const SizedBox(height: 10),
                        const Text('Contact Number',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: contactController,
                          decoration: _inputDecoration('Enter contact number'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        const Text('Email',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: emailController,
                          decoration: _inputDecoration('Enter email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        const Text('Occupation',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: occupationController,
                          decoration: _inputDecoration('Enter occupation'),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Civil Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: civilStatusController.text.isNotEmpty
                              ? civilStatusController.text
                              : null,
                          decoration:
                              _inputDecoration('Select your Civil Status'),
                          items: [
                            'Single',
                            'Married',
                            'Widowed',
                            'Divorced',
                            'Separated'
                          ]
                              .map((status) => DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              civilStatusController.text = value;
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text('Social Media Account',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        TextFormField(
                          controller: socialMediaController,
                          decoration: _inputDecoration(
                              'Enter your Social Media Account'),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: updateAdopterInfo,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}
