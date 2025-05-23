import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final int shelterId;

  const EditProfileScreen({Key? key, required this.shelterId})
      : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Map<String, dynamic>? shelterInfo;
  bool isLoading = true;

  XFile? coverImageFile;
  XFile? profileImageFile;
  Uint8List? coverImageBytes;
  Uint8List? profileImageBytes;

  final TextEditingController profileImageController = TextEditingController();
  final TextEditingController coverImageController = TextEditingController();

  Future<void> pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (type == 'cover') {
          coverImageFile = pickedFile;
          coverImageBytes = bytes;
          coverImageController.text = pickedFile.path;
        } else if (type == 'profile') {
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final String apiUrl =
        'http://127.0.0.1:5566/api/shelter/${widget.shelterId}';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        if (data != null && data is Map) {
          setState(() {
            shelterInfo = {
              ...?data['info'],
              ...?data['media'],
            };

            // Decode base64-encoded images
            if (shelterInfo!['shelter_profile'] != null) {
              profileImageBytes = base64Decode(shelterInfo!['shelter_profile']);
            }

            if (shelterInfo!['shelter_cover'] != null) {
              coverImageBytes = base64Decode(shelterInfo!['shelter_cover']);
            }

            profileImageController.text = shelterInfo!['shelter_profile'] ?? '';
            coverImageController.text = shelterInfo!['shelter_cover'] ?? '';
            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load shelter details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching shelter details: $e');
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey), // Sets hint text color to gray
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[200],
      // contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  Future<void> updateShelterDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final String apiUrl =
        'http://127.0.0.1:5566/api/shelter/${widget.shelterId}/update-info';
    final String mediaApiUrl =
        'http://127.0.0.1:5566/api/shelter/${widget.shelterId}/upload-media';

    try {
      // Update text fields
      final updateData = {
        "shelter_name": shelterInfo!['shelter_name'],
        "shelter_address": shelterInfo!['shelter_address'],
        "shelter_landmark": shelterInfo!['shelter_landmark'],
        "shelter_contact": shelterInfo!['shelter_contact'],
        "shelter_email": shelterInfo!['shelter_email'],
        "shelter_owner": shelterInfo!['shelter_owner'],
        "shelter_description": shelterInfo!['shelter_description'],
        "shelter_social": shelterInfo!['shelter_social'],
      };

      if (profileImageBytes != null) {
        updateData['shelter_profile'] = base64Encode(profileImageBytes!);
      }

      if (coverImageBytes != null) {
        updateData['shelter_cover'] = base64Encode(coverImageBytes!);
      }

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        // Upload media files if they are changed
        final mediaRequest =
            http.MultipartRequest('POST', Uri.parse(mediaApiUrl));
        mediaRequest.headers.addAll(
          {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );

        if (profileImageFile != null) {
          final profileBytes = await profileImageFile!.readAsBytes();
          final profileExtension =
              profileImageFile!.path.split('.').last.toLowerCase();
          final profileFileName =
              'profile_${widget.shelterId}.$profileExtension'; // Include file format
          mediaRequest.files.add(http.MultipartFile.fromBytes(
            'shelter_profile',
            profileBytes,
            filename: profileFileName,
            contentType: MediaType('image', profileExtension),
          ));
        }

        if (coverImageFile != null) {
          final coverBytes = await coverImageFile!.readAsBytes();
          final coverExtension =
              coverImageFile!.path.split('.').last.toLowerCase();
          final coverFileName =
              'cover_${widget.shelterId}.$coverExtension'; // Include file format
          mediaRequest.files.add(http.MultipartFile.fromBytes(
            'shelter_cover',
            coverBytes,
            filename: coverFileName,
            contentType: MediaType('image', coverExtension),
          ));
        }

        final mediaResponse = await mediaRequest.send();

        if (mediaResponse.statusCode == 200) {
          final mediaResponseBody = await mediaResponse.stream.bytesToString();
          final mediaResponseData = jsonDecode(mediaResponseBody);

          setState(() {
            shelterInfo = {
              ...shelterInfo!,
              ...mediaResponseData['data'], // Update shelter media info
            };

            // Reset the local image files after successful upload
            profileImageFile = null;
            coverImageFile = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Shelter details and media updated successfully!")),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          final errorResponse = await mediaResponse.stream.bytesToString();
          print(
              'Media upload failed: $errorResponse'); // Log the server response
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload media files")),
          );
        }
      } else {
        final errorMessage = jsonDecode(response.body)["message"] ??
            "Failed to update shelter details";
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

    if (shelterInfo == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load shelter information')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        title: Text('Edit Profile',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      backgroundColor: const Color.fromARGB(255, 239, 250, 255),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Photo Picker
                  Text(
                    'Shelter Cover Photo',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => pickImage('cover'),
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            image: coverImageBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(coverImageBytes!),
                                    fit: BoxFit.cover)
                                : (shelterInfo!['shelter_cover'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            shelterInfo!['shelter_cover']),
                                        fit: BoxFit.cover)
                                    : const DecorationImage(
                                        image: AssetImage(
                                            'assets/images/logo.png'),
                                        fit: BoxFit.cover)),
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: GestureDetector(
                            onTap: () => pickImage('cover'),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Shelter Logo',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => pickImage('profile'),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: profileImageBytes != null
                            ? MemoryImage(profileImageBytes!)
                            : (shelterInfo!['shelter_profile'] != null
                                ? NetworkImage(shelterInfo!['shelter_profile'])
                                : const AssetImage(
                                    'assets/images/logo.png')) as ImageProvider,
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
                  const SizedBox(height: 20),

                  // Form Fields
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Shelter Name',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_name'],
                          decoration: _inputDecoration('Enter shelter name'),
                          onChanged: (value) =>
                              shelterInfo!['shelter_name'] = value,
                        ),
                        const SizedBox(height: 10),
                        const Text('Address',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_address'],
                          decoration: _inputDecoration('Enter address'),
                          onChanged: (value) =>
                              shelterInfo!['shelter_address'] = value,
                        ),
                        const SizedBox(height: 10),
                        const Text('Landmark (Google Maps Link)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_landmark'],
                          decoration:
                              _inputDecoration('Enter landmark in google maps'),
                          onChanged: (value) =>
                              shelterInfo!['shelter_landmark'] = value,
                        ),
                        const SizedBox(height: 10),
                        const Text('Contact Number',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_contact'],
                          decoration: _inputDecoration('Enter contact number'),
                          onChanged: (value) =>
                              shelterInfo!['shelter_contact'] = value,
                        ),
                        const SizedBox(height: 10),
                        const Text('Email',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_email'],
                          decoration: _inputDecoration('Enter email'),
                          onChanged: (value) =>
                              shelterInfo!['shelter_email'] = value,
                        ),
                        const SizedBox(height: 10),
                        const Text('Social Media',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_social'],
                          decoration:
                              _inputDecoration('Enter social media link'),
                          onChanged: (value) =>
                              shelterInfo!['shelter_social'] = value,
                        ),
                        const SizedBox(height: 10),
                        const Text('Owner Name',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_owner'],
                          decoration: _inputDecoration(
                            'Enter owner name',
                          ),
                          onChanged: (value) =>
                              shelterInfo!['shelter_owner'] = value,
                        ),
                        const SizedBox(height: 10),
                        const Text('Description',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 5),
                        TextFormField(
                          initialValue: shelterInfo!['shelter_description'],
                          decoration: _inputDecoration('Enter description'),
                          onChanged: (value) =>
                              shelterInfo!['shelter_description'] = value,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            updateShelterDetails();
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.lightBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Save Changes',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
