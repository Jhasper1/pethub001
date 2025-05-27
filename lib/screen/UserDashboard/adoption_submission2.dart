import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shelter_clicked.dart';
import 'adopted_pets_screen.dart';
import 'adopted_pet_list_screen.dart';

class AdoptionForm extends StatefulWidget {
  final int petId;
  final int adopterId;
  final int shelterId;

  AdoptionForm({
    super.key,
    required this.petId,
    required this.adopterId,
    required this.shelterId,
  });

  @override
  _AdoptionFormState createState() => _AdoptionFormState();
}

class _AdoptionFormState extends State<AdoptionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Current step in the form (Adopter Info, Contact Info, etc.)
  int _currentStep = 0;

  // Loading state for fetching data
  bool isLoading = false;

  // Controllers for text fields
  TextEditingController adopterFNameController = TextEditingController();
  TextEditingController adopterLNameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController sexController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController occupationController = TextEditingController();
  TextEditingController civilStatusController = TextEditingController();
  TextEditingController socialMediaController = TextEditingController();

  final TextEditingController _altFNameController = TextEditingController();
  final TextEditingController _altLNameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _altContactNumberController =
      TextEditingController();
  final TextEditingController _altEmailController = TextEditingController();

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _idealPetDescController = TextEditingController();
  final TextEditingController _housingSituationController =
      TextEditingController();
  final TextEditingController _petsAtHomeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _familySupportController =
      TextEditingController();
  final TextEditingController _pastPetsController = TextEditingController();
  final TextEditingController _interviewSettingController =
      TextEditingController();
  final TextEditingController _adopterIDType = TextEditingController();
  final TextEditingController _altIDType = TextEditingController();

// Variables to store the bytes of the valid ID images
  Uint8List? _adopterValidIDBytes;
  Uint8List? _altValidIDBytes;
  XFile? _adopterValidID;
  XFile? _altValidID;

  // Image controllers for base64 encoding (will be implemented later)
  final List<String> images = List.generate(8, (index) => "");

  // Define a list of ID types
  final List<String> idTypes = [
    'Driver\'s License',
    'Passport',
    'National ID',
    'Voter\'s ID',
    'SSS ID',
    'Other',
  ];

  // Variable to store selected ID type
  String? selectedAdopterIDType;
  String? selectedAltIDType;

  @override
  void initState() {
    super.initState();
    fetchAdopterInfo();
  }

  List<String> labels = [
    'Living Room',
    'Kitchen',
    'Bedroom',
    'Bathroom',
    'Yard/Outdoor',
    'Front View',
    'Dining Area',
    'Others',
  ];

  // List<Uint8List?> imageBytesList = List.generate(8, (_) => null);
  List<Uint8List?> imageBytesList = List<Uint8List?>.filled(8, null);
  final List<XFile?> _homeImages = List<XFile?>.filled(8, null);

  // Define steps and their widgets
  List<Widget> get _formSteps => [
        _buildAdopterInfoStep(),
        _buildContactInfoStep(),
        _buildQuestionnaireStep(),
        _buildPhotoImagesStep(),
        _buildReviewStep(),
      ];

  Future<void> fetchAdopterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = 'http://127.0.0.1:5566/api/user/${widget.adopterId}';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Adopter Info Only: $data");

        setState(() {
          var adopterInfo = data['data'] ?? {};

          adopterFNameController.text = adopterInfo!['first_name'] ?? '';
          adopterLNameController.text = adopterInfo!['last_name'] ?? '';
          ageController.text = adopterInfo!['age']?.toString() ?? '';
          sexController.text = adopterInfo!['sex'] ?? '';
          addressController.text = adopterInfo!['address'] ?? '';
          contactNumberController.text = adopterInfo!['contact_number'] ?? '';
          emailController.text = adopterInfo!['email'] ?? '';
          occupationController.text = adopterInfo!['occupation'] ?? '';
          civilStatusController.text = adopterInfo!['civil_status'] ?? '';
          socialMediaController.text = adopterInfo!['social_media'] ?? '';
        });
      } else {
        throw Exception('Failed to load adopter info');
      }
    } catch (e) {
      print("Error fetching adopter info: $e");
      setState(() {});
    }
  }

  Future<void> _submitAdoptionForm() async {
    // Debug print to verify IDs
    print('Submitting adoption with:');
    print('- Shelter ID: ${widget.shelterId}');
    print('- Pet ID: ${widget.petId}');
    print('- Adopter ID: ${widget.adopterId}');
    print('= Application ID: &{widget.applicationId}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authorization token is missing")),
      );
      return;
    }

    if (_adopterValidIDBytes == null || _altValidIDBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both valid IDs")),
      );
      return;
    }

    // Verify all home images are uploaded
    for (int i = 0; i < _homeImages.length; i++) {
      if (_homeImages[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please upload image for ${labels[i]}")),
        );
        return;
      }
    }

    try {
      var uri = Uri.parse(
        'http://127.0.0.1:5566/api/adopter/${widget.shelterId}/${widget.petId}/${widget.adopterId}/adoption',
      );

      print('Final API URL: ${uri.toString()}');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields.addAll({
        'alt_f_name': _altFNameController.text,
        'alt_l_name': _altLNameController.text,
        'relationship': _relationshipController.text,
        'alt_contact_number': _altContactNumberController.text,
        'alt_email': _altEmailController.text,
        'reason_for_adoption': _reasonController.text,
        'ideal_pet_description': _idealPetDescController.text,
        'housing_situation': _housingSituationController.text,
        'pets_at_home': _petsAtHomeController.text,
        'allergies': _allergiesController.text,
        'family_support': _familySupportController.text,
        'past_pets': _pastPetsController.text,
        'interview_setting': _interviewSettingController.text,
        'adopter_id_type': selectedAdopterIDType ?? '',
        'alt_id_type': selectedAltIDType ?? '',
      });

      // Add ID images
      request.files.add(http.MultipartFile.fromBytes(
        'adopter_valid_id',
        _adopterValidIDBytes!,
        filename: 'adopter_id.jpg',
      ));

      request.files.add(http.MultipartFile.fromBytes(
        'alt_valid_id',
        _altValidIDBytes!,
        filename: 'alt_id.jpg',
      ));

      // Add home images
      for (int i = 0; i < _homeImages.length; i++) {
        final file = _homeImages[i]!;
        request.files.add(http.MultipartFile.fromBytes(
          'home_image${i + 1}',
          await file.readAsBytes(),
          filename: 'home_image${i + 1}.jpg',
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Success response: $responseData');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Adoption submitted successfully")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) {
              print(
                  'Navigating to ApplicationDetailsScreen with applicationId:');
              return AdoptedPetListScreen(
                adopterId: widget.adopterId,
                applicationId: 0,
              );
            },
          ),
        );
      } else {
        print('Error response: ${response.body}');
        String message = "Failed to submit adoption";
        try {
          final body = jsonDecode(response.body);
          message = body['message'] ?? message;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print('Exception during submission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission error: ${e.toString()}')),
      );
    }
  }

// Default image (replace with your asset or network image if needed)
  final String defaultImagePath = 'assets/images/logo.png';

  Future<void> _pickAdopterValidID() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // Convert to bytes
      setState(() {
        _adopterValidIDBytes = bytes; // Store the bytes for the image
      });
    }
  }

  Future<void> _pickAltValidID() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // Convert to bytes
      setState(() {
        _altValidIDBytes = bytes; // Store the bytes for the image
      });
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey), // Sets hint text color to gray
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  Widget _buildAdopterValidIDPreview() {
    return GestureDetector(
      onTap: _pickAdopterValidID,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adopted Valid ID',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              image: _adopterValidIDBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_adopterValidIDBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _adopterValidIDBytes == null
                ? const Center(
                    child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAltValidIDPreview() {
    return GestureDetector(
      onTap: _pickAltValidID,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Second Contact Valid ID"),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: _altValidIDBytes != null
                    ? MemoryImage(_altValidIDBytes!) // Use MemoryImage
                    : const AssetImage('assets/images/logo.png')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: _altValidIDBytes == null
                ? const Center(
                    child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageForIndex(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _homeImages[index] = pickedFile;
        imageBytesList[index] = bytes;
      });
    }
  }

  Widget _buildImagePreview(int index, String label) {
    return GestureDetector(
      onTap: () => _pickImageForIndex(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: imageBytesList[index] != null
                    ? MemoryImage(imageBytesList[index]!)
                    : AssetImage(defaultImagePath) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: imageBytesList[index] == null
                ? Center(
                    child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // Method to go to the next step
  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_currentStep < _formSteps.length - 1) {
          _currentStep++;
        } else {
          // If it's the last step, you can handle form submission here
          // Submit the form data to your API
          _submitAdoptionForm();
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildAdopterInfoStep() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ADOPTER INFORMATION",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('First Name',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: adopterFNameController,
                        readOnly: true,
                        decoration: _inputDecoration('Adopter First Name'),
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Name',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: adopterLNameController,
                        readOnly: true,
                        decoration: _inputDecoration('Adopter Last Name'),
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Age',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: ageController,
                        readOnly: true,
                        decoration: _inputDecoration('Age'),
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sex',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: sexController,
                        readOnly: true,
                        decoration: _inputDecoration('Sex'),
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Address',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextFormField(
                controller: addressController,
                readOnly: true,
                decoration: _inputDecoration('Address'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact Number',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: contactNumberController,
                        readOnly: true,
                        decoration: _inputDecoration('Contact Number'),
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email Address',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: emailController,
                        readOnly: true,
                        decoration: _inputDecoration('Email'),
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Occupation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextFormField(
                controller: occupationController,
                readOnly: true,
                decoration: _inputDecoration('Occupation'),
              ),
              const SizedBox(height: 10),
              const Text('Civil Status',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextFormField(
                controller: civilStatusController,
                readOnly: true,
                decoration: _inputDecoration('Civil Status'),
              ),
              const SizedBox(height: 10),
              const Text('Social Media',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextFormField(
                controller: socialMediaController,
                readOnly: true,
                decoration: _inputDecoration('Social Media'),
              ),
              SizedBox(height: 10),
              const Text('Type of ID',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: selectedAdopterIDType,
                decoration: _inputDecoration('Select Type of ID'),
                items: idTypes.map((String idType) {
                  return DropdownMenuItem<String>(
                    value: idType,
                    child: Text(idType),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedAdopterIDType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an ID type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildAdopterValidIDPreview()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "SECOND CONTACT PERSON INFORMATION",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('First Name',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _altFNameController,
                        decoration: _inputDecoration('First Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a first name';
                          }
                          return null;
                        },
                      ),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Name',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _altLNameController,
                        decoration: _inputDecoration('Last Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a last name';
                          }
                          return null;
                        },
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Relationship to the Adopter',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextFormField(
                controller: _relationshipController,
                decoration:
                    _inputDecoration('Enter your relationship to the Adopter'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter type of relationship';
                  }
                  return null;
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _altContactNumberController,
                  decoration: InputDecoration(labelText: 'Contact Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a contact number';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _altEmailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an Email Address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: DropdownButtonFormField<String>(
                  value: selectedAltIDType,
                  decoration: InputDecoration(labelText: 'Type of ID'),
                  items: idTypes.map((String idType) {
                    return DropdownMenuItem<String>(
                      value: idType,
                      child: Text(idType),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAltIDType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an ID type';
                    }
                    return null;
                  },
                ),
              ),
              _buildAltValidIDPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionnaireStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(labelText: 'Reason for Adoption'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a reason';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _idealPetDescController,
                  decoration:
                      InputDecoration(labelText: 'Ideal Pet Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe your ideal pet';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _housingSituationController,
                  decoration: InputDecoration(labelText: 'Housing Situation'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe your housing situation';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _petsAtHomeController,
                  decoration: InputDecoration(labelText: 'Pets at Home'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please mention any pets at home';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _allergiesController,
                  decoration: InputDecoration(labelText: 'Any Allergies'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please mention any allergies';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _familySupportController,
                  decoration: InputDecoration(labelText: 'Family Support'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please mention if your family supports the adoption';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _pastPetsController,
                  decoration: InputDecoration(labelText: 'Past Pet Ownership'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe any past pets';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextFormField(
                  controller: _interviewSettingController,
                  decoration:
                      InputDecoration(labelText: 'Preferred Interview Setting'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide your preferred interview setting';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoImagesStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: List.generate(4, (rowIndex) {
              int first = rowIndex * 2;
              int second = first + 1;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildImagePreview(first, labels[first]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildImagePreview(second, labels[second]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text('Review All Information:'),
            // Display all information entered by the user
            Text('Adopter Name: ${adopterFNameController.text}'),
            Text('Contact Number: ${contactNumberController.text}'),
            Text('Relationship: ${_relationshipController.text}'),

            // Display other fields similarly...
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        title: Text('Adoption Form',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: _formSteps[_currentStep], // Show current step
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (disabled if at step 0)
                  if (_currentStep > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousStep,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black, // sets text/icon color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Expanded(
                      child: SizedBox(
                          height: 55), // Placeholder to keep layout balanced
                    ),

                  const SizedBox(width: 16), // Space between buttons

                  // Next or Submit Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white, // sets text/icon color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep == _formSteps.length - 1
                            ? 'Submit'
                            : 'Next',
                      ),
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
