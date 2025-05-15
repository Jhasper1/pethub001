import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShelterDonationsScreen extends StatefulWidget {
  final int shelterId;

  const ShelterDonationsScreen({Key? key, required this.shelterId})
      : super(key: key);

  @override
  _ShelterDonationsScreenState createState() => _ShelterDonationsScreenState();
}

class _ShelterDonationsScreenState extends State<ShelterDonationsScreen> {
  Map<String, dynamic>? shelterDonations;
  bool isLoading = true;
  XFile? qrImageFile;
  Uint8List? _qrImageBytes;
  String errorMessage = '';
  final _accountnumberController = TextEditingController();
  final _accountnameController = TextEditingController();

  final TextEditingController qrImageController = TextEditingController();



  @override
  void initState() {
    super.initState();
    fetchShelterDonations();
  }

  Future<void> fetchShelterDonations() async {
        final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.shelterId}/get/donationinfo';
    try {
      final response = await http.get(Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        final donationDataResponse = data['data'];

        setState(() {
          shelterDonations = donationDataResponse;
          _accountnumberController.text =
              donationDataResponse['account_number'] ?? '';
          _accountnameController.text =
              donationDataResponse['account_name'] ?? '';
          // Decode image if available
          if (donationDataResponse['qr_image'] != null &&
              donationDataResponse['qr_image'].isNotEmpty) {
            _qrImageBytes = base64Decode(donationDataResponse['qr_image']);
          }

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pet data');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching pet data.";
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _qrImageBytes = bytes;
      });
    }
  }



  InputDecoration _buildTextFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  Future<void> updatedonationDetails() async {
    final url = Uri.parse(
        'http://127.0.0.1:5566/shelter/${widget.shelterId}/update/donationinfo');

    var request = http.MultipartRequest('PUT', url);

    // Add text fields
    request.fields['account_number'] = _accountnumberController.text;
    request.fields['account_name'] = _accountnameController.text;

    // Add image file (if selected)
    if (_qrImageBytes != null && _qrImageBytes!.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'qr_image', // Must match backend field
          _qrImageBytes!,
          filename: 'pet_image.jpg',
          contentType:
              MediaType('image', 'jpeg'), // or 'png', depending on your image
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet updated successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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

    if (shelterDonations == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load donation details')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Donation Information',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Picker
            const SizedBox(height: 50),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _qrImageBytes != null
                          ? MemoryImage(_qrImageBytes!)
                          : (shelterDonations!['qr_image'] != null
                                  ? NetworkImage(shelterDonations!['qr_image'])
                                  : const AssetImage('assets/images/logo.png'))
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius:
                        BorderRadius.circular(10), // Rounded corners (optional)
                    color: Colors.grey[300], // Optional background color
                  ),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blueAccent,
                      child:
                          Icon(Icons.camera_alt, size: 15, color: Colors.white),
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
                  Text('Account Number',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _accountnumberController,
                    decoration:
                        _buildTextFieldDecoration('Enter your account number'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    onChanged: (value) =>
                        shelterDonations!['account_number'] = value,
                  ),
                  const SizedBox(height: 10),
                  Text('Account Name',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _accountnameController,
                    decoration:
                        _buildTextFieldDecoration('Enter your account name'),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    onChanged: (value) =>
                        shelterDonations!['account_name'] = value,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            // title: const Text("Confirm"),
                            content: const Text(
                                "Are you sure you want to save the changes?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close dialog, cancel action
                                },
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close dialog
                                  updatedonationDetails(); // Proceed with the update
                                },
                                child: const Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(color: Colors.white),
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
}
