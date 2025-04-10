import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class UserEditProfileScreen extends StatefulWidget {
  final int adopterId;

  const UserEditProfileScreen({Key? key, required this.adopterId}) : super(key: key);

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

  Future<void> pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (type == 'profile') {
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
    final String apiUrl = 'http://127.0.0.1:5566/user/${widget.adopterId}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        if (data != null && data is Map) {
          setState(() {
            adopterInfo = {
              ...?data['info'],
              ...?data['media'],
            };

            // Initialize controllers with current values
            firstNameController.text = adopterInfo!['first_name'] ?? '';
            lastNameController.text = adopterInfo!['last_name'] ?? '';
            addressController.text = adopterInfo!['address'] ?? '';
            contactController.text = adopterInfo!['contact_number']?.toString() ?? '';
            emailController.text = adopterInfo!['email'] ?? '';

            // Decode base64-encoded images
            if (adopterInfo!['adopter_profile'] != null) {
              profileImageBytes = base64Decode(adopterInfo!['adopter_profile']);
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
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  Future<void> updateAdopterDetails() async {
    final String apiUrl = 'http://127.0.0.1:5566/users/${widget.adopterId}/update-info';
    final String mediaApiUrl = 'http://127.0.0.1:5566/users/${widget.adopterId}/upload-media';

    try {
      // Update text fields
      final updateData = {
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "address": addressController.text,
        "contact_number": contactController.text,
        "email": emailController.text,
      };

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        // Upload media files if they are changed
        if (profileImageFile != null) {
          final mediaRequest = http.MultipartRequest('POST', Uri.parse(mediaApiUrl));
          final profileBytes = await profileImageFile!.readAsBytes();
          final profileExtension = profileImageFile!.path.split('.').last.toLowerCase();
          final profileFileName = 'profile_${widget.adopterId}.$profileExtension';

          mediaRequest.files.add(http.MultipartFile.fromBytes(
            'adopter_profile',
            profileBytes,
            filename: profileFileName,
            contentType: MediaType('image', profileExtension),
          ));

          final mediaResponse = await mediaRequest.send();

          if (mediaResponse.statusCode != 200) {
            throw Exception('Failed to upload profile image');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        final errorMessage = jsonDecode(response.body)["message"] ?? "Failed to update profile";
        throw Exception(errorMessage);
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Picker
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: GestureDetector(
                  onTap: () => pickImage('profile'),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageBytes != null
                        ? MemoryImage(profileImageBytes!)
                        : (adopterInfo!['adopter_profile'] != null
                        ? MemoryImage(base64Decode(adopterInfo!['adopter_profile']))
                        : const AssetImage('assets/images/logo.png')) as ImageProvider,
                    child: const Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
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
                  const Text('First Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: firstNameController,
                    decoration: _inputDecoration('Enter first name'),
                  ),
                  const SizedBox(height: 10),

                  const Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: lastNameController,
                    decoration: _inputDecoration('Enter last name'),
                  ),
                  const SizedBox(height: 10),

                  const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: addressController,
                    decoration: _inputDecoration('Enter address'),
                  ),
                  const SizedBox(height: 10),

                  const Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: contactController,
                    decoration: _inputDecoration('Enter contact number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),

                  const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration('Enter email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: updateAdopterDetails,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}