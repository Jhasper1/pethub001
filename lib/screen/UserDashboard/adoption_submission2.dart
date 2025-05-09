import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shelter_clicked.dart';

class AdoptionForm extends StatefulWidget {
  final int petId;
  final int adopterId;
  final int shelterId;

  AdoptionForm(
      {super.key,
      required this.petId,
      required this.adopterId,
      required this.shelterId});

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
  TextEditingController adopterNameController = TextEditingController();
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

          adopterNameController.text =
              "${adopterInfo!['first_name'] ?? ''} ${adopterInfo!['last_name'] ?? ''}";
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Check if the form is valid
    if (!_formKey.currentState!.validate()) return;

    // Ensure that the token is not null
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authorization token is missing")),
      );
      return;
    }

    // Ensure that the images are not null before proceeding
    if (_adopterValidIDBytes == null || _altValidIDBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both valid IDs")),
      );
      return;
    }

    var uri = Uri.parse(
      'http://127.0.0.1:5566/api/adopter/${widget.shelterId}/${widget.petId}/${widget.adopterId}/adoption',
    );
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    // Form fields
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
      'adopter_id_type': _adopterIDType.text,
      'alt_id_type': _altIDType.text,
    });

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

    print('Picked Adopter ID Bytes: ${_adopterValidIDBytes?.length}');
    print('Picked Alt ID Bytes: ${_altValidIDBytes?.length}');

    // Add home images (with null checks for each image)
    for (int i = 0; i < _homeImages.length; i++) {
      final file = _homeImages[i];
      if (file != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'home_image${i + 1}',
          await file.readAsBytes(),
          filename: 'home_image${i + 1}.jpg',
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Home image ${i + 1} is missing")),
        );
        return;
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Adoption submitted successfully")),
        );
        _formKey.currentState!.reset();
        setState(() => _currentStep = 0);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ShelterDetailsScreen(
              shelterId: widget.shelterId,
              adopterId: widget.adopterId,
            ),
          ),
        );
      } else {
        String message = "Failed to submit adoption";
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) message = body['message'];
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      String errorMessage = 'Something went wrong';
      if (e is http.ClientException) {
        errorMessage = 'Network error: Unable to connect';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timed out';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
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

  Widget _buildAdopterValidIDPreview() {
    return GestureDetector(
      onTap: _pickAdopterValidID,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Adopter Valid ID"),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: _adopterValidIDBytes != null
                    ? MemoryImage(_adopterValidIDBytes!) // Use MemoryImage
                    : const AssetImage('assets/images/logo.png')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: adopterNameController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Adopter Name'),
            ),
            TextFormField(
              controller: ageController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Age'),
            ),
            TextFormField(
              controller: sexController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Sex'),
            ),
            TextFormField(
              controller: addressController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            TextFormField(
              controller: contactNumberController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Contact Number'),
            ),
            TextFormField(
              controller: emailController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: occupationController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Occupation'),
            ),
            TextFormField(
              controller: civilStatusController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Civil Status'),
            ),
            TextFormField(
              controller: socialMediaController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Social Media'),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _altIDType,
              decoration: InputDecoration(labelText: 'Type of ID'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please input ID type';
                }
                return null;
              },
            ),
            _buildAdopterValidIDPreview()
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
          child: Column(
        children: [
          Text("SECOND CONTACT PERSON INFORMATION"),
          TextFormField(
            controller: _altFNameController,
            decoration: InputDecoration(labelText: 'First Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a first name';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _altLNameController,
            decoration: InputDecoration(labelText: 'Last Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a last name';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _relationshipController,
            decoration:
                InputDecoration(labelText: 'Relationship to the Adopter'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the relationship';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _altContactNumberController,
            decoration: InputDecoration(labelText: 'Contact Number'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a contact number';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _altEmailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an Email Address';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _adopterIDType,
            decoration: InputDecoration(labelText: 'Type of ID'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please input ID type';
              }
              return null;
            },
          ),
          _buildAltValidIDPreview()
        ],
      )),
    );
  }

  Widget _buildQuestionnaireStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(labelText: 'Reason for Adoption'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide a reason';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _idealPetDescController,
            decoration: InputDecoration(labelText: 'Ideal Pet Description'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your ideal pet';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _housingSituationController,
            decoration: InputDecoration(labelText: 'Housing Situation'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your housing situation';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _petsAtHomeController,
            decoration: InputDecoration(labelText: 'Pets at Home'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please mention any pets at home';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _allergiesController,
            decoration: InputDecoration(labelText: 'Any Allergies'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please mention any allergies';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _familySupportController,
            decoration: InputDecoration(labelText: 'Family Support'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please mention if your family supports the adoption';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _pastPetsController,
            decoration: InputDecoration(labelText: 'Past Pet Ownership'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe any past pets';
              }
              return null;
            },
          ),
          TextFormField(
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
        ],
      ),
    );
  }

  Widget _buildPhotoImagesStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(4, (rowIndex) {
            int first = rowIndex * 2;
            int second = first + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(child: _buildImagePreview(first, labels[first])),
                  const SizedBox(width: 16),
                  Expanded(child: _buildImagePreview(second, labels[second])),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Review All Information:'),
          // Display all information entered by the user
          Text('Adopter Name: ${adopterNameController.text}'),
          Text('Contact Number: ${contactNumberController.text}'),
          Text('Relationship: ${_relationshipController.text}'),
          // Display other fields similarly...
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adoption Form'),
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
                    ElevatedButton(
                      onPressed: _previousStep,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 100), // Placeholder to balance layout

                  // Next or Submit Button
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == _formSteps.length - 1 ? 'Submit' : 'Next',
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
