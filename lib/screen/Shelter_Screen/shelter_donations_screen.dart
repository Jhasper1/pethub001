import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ShelterDonationsScreen extends StatefulWidget {
  final int shelterId;

  const ShelterDonationsScreen ({Key? key, required this.shelterId}) : super(key: key);

  @override
  _ShelterDonationsScreenState createState() => _ShelterDonationsScreenState();
}

class _ShelterDonationsScreenState extends State<ShelterDonationsScreen > {
  Map<String, dynamic>? shelterDonations;
  bool isLoading = true;
  XFile? qrImageFile;
  Uint8List? _qrImageBytes;
  String errorMessage = '';
  final _accountnumberController = TextEditingController();
  final _accountnameController = TextEditingController();

  final TextEditingController qrImageController = TextEditingController();

  Future<void> pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (type == 'qr') {
          qrImageFile = pickedFile;
          _qrImageBytes = bytes;
          qrImageController.text = pickedFile.path;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchShelterDonations();
  }

 Future<void> fetchShelterDonations() async {
    final url = 'http://127.0.0.1:5566/shelter/${widget.shelterId}/get/donationinfo';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        final donationDataResponse = data['data'];

        setState(() {
          shelterDonations = donationDataResponse;
          _accountnumberController.text = donationDataResponse['account_number'] ?? '';
          _accountnameController.text = donationDataResponse['account_name'] ?? '';
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

 InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: Colors.grey), // Sets hint text color to gray
    border: InputBorder.none, // Removes the outline
    filled: true,
    fillColor: Colors.grey[200],
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
          contentType: MediaType('image', 'jpeg' 'png' 'jpg' 'webp'),
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



// Future<void> updatedonationDetails() async {
//   final String apiUrl = 'http://127.0.0.1:5566/shelter/${widget.shelterId}/update/donationinfo';

//   try {
//     final updateData = {
//       "account_number": shelterDonations!['account_number'],
//       "account_name": shelterDonations!['account_name'],
//       "qr_image": _qrImageBytes != null ? [base64Encode(_qrImageBytes!)] : [],
//     };

//     final response = await http.put(
//       Uri.parse(apiUrl),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(updateData),
//     );

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Donation details updated successfully!")),
//       );
//       Navigator.pop(context, true);
//     } else {
//       final errorMessage = jsonDecode(response.body)["message"] ?? "Failed to update donation details";
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMessage)),
//       );
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("An error occurred: ${e.toString()}")),
//     );
//   }
// }




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
        title: const Text('Donation Information'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Picker
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 100,
                  backgroundImage: _qrImageBytes != null
                      ? MemoryImage(_qrImageBytes!)
                      : (shelterDonations!['qr_image'] != null
                          ? NetworkImage(shelterDonations!['qr_image'])
                          : const AssetImage('assets/images/logo.png')) as ImageProvider,
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blueAccent,
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
                  const Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    initialValue: shelterDonations!['account_number'],
                    decoration: _inputDecoration('Enter your account number'),
                    onChanged: (value) => shelterDonations!['account_number'] = value,
                  ),
                  const SizedBox(height: 10),

                  const Text('Account Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    initialValue: shelterDonations!['account_name'],
                    decoration: _inputDecoration('Enter your account name'),
                    onChanged: (value) => shelterDonations!['account_name'] = value,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      updatedonationDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blueAccent,
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
