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
  Uint8List? coverImageBytes;
  Uint8List? profileImageBytes;

  final TextEditingController profileImageController = TextEditingController();
  final TextEditingController ownerController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Future<void> pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (type == 'profile') {
          profileImageFile = pickedFile;
          profileImageBytes = bytes;
          profileImageController.text = pickedFile.path;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchShelterInfo();
  }

  Future<void> fetchShelterInfo() async {
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

            // Decode base64-encoded images
            if (adopterInfo!['adopter_profile'] != null) {
              profileImageBytes = base64Decode(adopterInfo!['adopter_profile']);
            }

            if (adopterInfo!['adopter_cover'] != null) {
              coverImageBytes = base64Decode(adopterInfo!['adopter_cover']);
            }

            profileImageController.text = adopterInfo!['adopter_profile'] ?? '';
            ownerController.text = adopterInfo!['adopter_owner'] ?? '';
            descriptionController.text = adopterInfo!['adopter_description'] ?? '';
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  Future<void> updateShelterDetails() async {
    final String apiUrl = 'http://127.0.0.1:5566/users/${widget.adopterId}/update';
    final String mediaApiUrl = 'http://127.0.0.1:5566/users/${widget.adopterId}/upload-media';

    try {
      // Update text fields
      final updateData = {
        "first_name": adopterInfo!['first_name'],
        "last_name": adopterInfo!['last_name'],
        "address": adopterInfo!['address'],
        "contact_number": adopterInfo!['contact_number'],
        "email": adopterInfo!['email'],
      };

      if (profileImageBytes != null) {
  updateData['adopter_profile'] = base64Encode(profileImageBytes!);
}

final response = await http.put(
  Uri.parse(apiUrl),
  headers: {"Content-Type": "application/json"},
  body: jsonEncode(updateData),
);


      if (response.statusCode == 200) {
        // Upload media files if they are changed
        final mediaRequest = http.MultipartRequest('POST', Uri.parse(mediaApiUrl));

        if (profileImageFile != null) {
          final profileBytes = await profileImageFile!.readAsBytes();
          final profileExtension = profileImageFile!.path.split('.').last.toLowerCase();
          final profileFileName = 'profile_${widget.adopterId}.$profileExtension'; // Include file format
          mediaRequest.files.add(http.MultipartFile.fromBytes(
            'adopter_profile',
            profileBytes,
            filename: profileFileName,
            contentType: MediaType('image', profileExtension),
          ));
        }

        final mediaResponse = await mediaRequest.send();

        if (mediaResponse.statusCode == 200) {
          final mediaResponseBody = await mediaResponse.stream.bytesToString();
          final mediaResponseData = jsonDecode(mediaResponseBody);

          setState(() {
            adopterInfo = {
              ...adopterInfo!,
              ...mediaResponseData['data'], // Update shelter media info
            };

            // Reset the local image files after successful upload
            profileImageFile = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Adopter details and media updated successfully!")),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          final errorResponse = await mediaResponse.stream.bytesToString();
          print('Media upload failed: $errorResponse'); // Log the server response
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload media files")),
          );
        }
      } else {
        final errorMessage = jsonDecode(response.body)["message"] ?? "Failed to update adopter details";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error during updateShelterDetails: $e'); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
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
        body: Center(child: Text('Failed to load adopter information')),
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
              child: GestureDetector(
                onTap: () => pickImage('profile'),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImageBytes != null
                      ? MemoryImage(profileImageBytes!)
                      : (adopterInfo!['adopter_profile'] != null
                          ? NetworkImage(adopterInfo!['adopter_profile'])
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
            const SizedBox(height: 20),

            // Form Fields
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('first Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    initialValue: adopterInfo!['first_name'],
                    decoration: _inputDecoration('Enter first name'),
                    onChanged: (value) => adopterInfo!['first_name'] = value,
                  ),
                  const SizedBox(height: 10),

                  const Text('last Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    initialValue: adopterInfo!['last_name'],
                    decoration: _inputDecoration('Enter last name'),
                    onChanged: (value) => adopterInfo!['last_name'] = value,
                  ),
                  const SizedBox(height: 10),

                  const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    initialValue: adopterInfo!['address'],
                    decoration: _inputDecoration('Enter address'),
                    onChanged: (value) => adopterInfo!['address'] = value,
                  ),
                  const SizedBox(height: 10),

                  const Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    initialValue: adopterInfo!['contact_number'],
                    decoration: _inputDecoration('Enter contact number'),
                    onChanged: (value) => adopterInfo!['contact_number'] = value,
                  ),
                  const SizedBox(height: 10),

                  const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    initialValue: adopterInfo!['email'],
                    decoration: _inputDecoration('Enter email'),
                    onChanged: (value) => adopterInfo!['email'] = value,
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      updateShelterDetails();
                    },
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
