import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPetScreen extends StatefulWidget {
  final int petId;
  final int shelterId;

  const EditPetScreen(
      {super.key, required this.petId, required this.shelterId});

  @override
  _EditPetScreenState createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();

  String? _selectedPetType;
  String? _selectedAgeType;
  String? _selectedSex;
  Uint8List? _imageBytes;
  Uint8List? _petVaccineBytes;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = 'http://127.0.0.1:5566/api/shelter/${widget.petId}/petinfo';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        final petDataResponse = data['data'];

        setState(() {
          _nameController.text = petDataResponse['pet_name'] ?? '';
          _ageController.text = petDataResponse['pet_age']?.toString() ?? '';
          _descriptionController.text =
              petDataResponse['pet_descriptions'] ?? '';
          _selectedAgeType = petDataResponse['age_type'] ?? '';
          _selectedSex = petDataResponse['pet_sex'] ?? '';
          _sizeController.text = petDataResponse['pet_size']?.toString() ?? '';
          _selectedPetType = petDataResponse['pet_type'] ?? '';

          // Fetch image from petmedia field
          final petImage = petDataResponse['petmedia'];
          if (petImage != null) {
            final petImageBase64 = petImage['pet_image1'];
            if (petImageBase64 != null && petImageBase64.isNotEmpty) {
              _imageBytes = base64Decode(petImageBase64);
            }
          }

          final petVaccine = petDataResponse['petmedia'];
          if (petVaccine != null) {
            final petVaccine64 = petVaccine['pet_vaccine'];
            if (petVaccine64 != null && petVaccine64.isNotEmpty) {
              _petVaccineBytes = base64Decode(petVaccine64);
            }
          }

          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load pet data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        errorMessage = "Error fetching pet data.";
        isLoading = false;
      });
    }
  }

  Future<void> _pickPetImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickVaccineImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _petVaccineBytes = bytes;
      });
    }
  }

  Future<void> _updateForm() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse(
        'http://127.0.0.1:5566/api/shelter/${widget.petId}/update-pet-info');

    var request = http.MultipartRequest('PUT', url);

    request.headers.addAll({
      "Authorization": "Bearer $token",
    });

    // Add text fields
    request.fields['pet_name'] = _nameController.text;
    request.fields['pet_age'] = _ageController.text;
    request.fields['pet_size'] = _sizeController.text;
    request.fields['age_type'] = _selectedAgeType!;
    request.fields['pet_sex'] = _selectedSex!;
    request.fields['pet_type'] = _selectedPetType!;
    request.fields['pet_descriptions'] = _descriptionController.text;

    // Upload pet image
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'pet_image1',
          _imageBytes!,
          filename: 'pet_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

// Upload vaccine image
    if (_petVaccineBytes != null && _petVaccineBytes!.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'pet_vaccine',
          _petVaccineBytes!,
          filename: 'pet_vaccine.jpg',
          contentType: MediaType('image', 'jpeg'),
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

  String? _validateSize(String? value) {
    if (value == null || value.isEmpty) return 'Enter pet size';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value))
      return 'Only numbers allowed';
    return null;
  }

  InputDecoration _buildTextFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        title: Text('Edit Pet Information',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: _buildBodyContent(),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildBodyContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                color: const Color.fromARGB(255, 239, 250, 255),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pet Image',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        SizedBox(height: 5),
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: _pickPetImage,
                            child: CircleAvatar(
                              radius: 75,
                              backgroundImage: _imageBytes != null
                                  ? MemoryImage(_imageBytes!)
                                  : const AssetImage('assets/images/logo.png')
                                      as ImageProvider,
                              child: const Align(
                                alignment: Alignment.bottomRight,
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.lightBlue,
                                  child: Icon(Icons.camera_alt,
                                      size: 15, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Tap to change image',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600]),
                            )),
                        const SizedBox(height: 15),
                        Text(
                          'Pet Type',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        SizedBox(height: 5),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPetTypeButton('Dog', 'images/dog.png'),
                              SizedBox(width: 30),
                              _buildPetTypeButton('Cat', 'images/cat.png'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Select the type of pet',
                            style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Pet Name',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                            SizedBox(height: 5),
                            TextFormField(
                              controller: _nameController,
                              decoration: _buildTextFieldDecoration('Pet Name'),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter pet name'
                                  : null,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z\s]'))
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      'Pet Size',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  TextFormField(
                                    controller: _sizeController,
                                    decoration:
                                        _buildTextFieldDecoration('Pet Size')
                                            .copyWith(
                                      suffixText: 'KG',
                                      suffixStyle:
                                          TextStyle(color: Colors.grey[600]),
                                    ),
                                    validator: _validateSize,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Pet Sex',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                                SizedBox(height: 5),
                                DropdownButtonFormField<String>(
                                  value: _selectedSex,
                                  decoration:
                                      _buildTextFieldDecoration('Pet Sex'),
                                  items: ['Male', 'Female'].map((val) {
                                    return DropdownMenuItem(
                                        value: val, child: Text(val));
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedSex = val);
                                  },
                                  validator: (val) =>
                                      val == null ? 'Select sex' : null,
                                ),
                              ],
                            )),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                                child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Pet Age',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                                SizedBox(height: 5),
                                TextFormField(
                                  controller: _ageController,
                                  decoration:
                                      _buildTextFieldDecoration('Pet Age'),
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'Enter age'
                                      : null,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                ),
                              ],
                            )),
                            SizedBox(width: 10),
                            Expanded(
                                child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Pet Age Type',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                                SizedBox(height: 5),
                                DropdownButtonFormField<String>(
                                  value: _selectedAgeType,
                                  decoration:
                                      _buildTextFieldDecoration('Age Type'),
                                  items: ['Month', 'Year'].map((val) {
                                    return DropdownMenuItem(
                                        value: val, child: Text(val));
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedAgeType = val);
                                  },
                                  validator: (val) =>
                                      val == null ? 'Select age type' : null,
                                ),
                              ],
                            )),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Pet Description',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                            SizedBox(height: 5),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 6,
                              decoration:
                                  _buildTextFieldDecoration('Pet Description'),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter description'
                                  : null,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Note: Add any details about the pet like behavior, health, etc.',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    )),
              ),
              const SizedBox(height: 15),
              Card(
                color: const Color.fromARGB(255, 239, 250, 255),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pet Vaccine',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      SizedBox(height: 5),
                      Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: _pickVaccineImage,
                          child: Container(
                        
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              image: _petVaccineBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_petVaccineBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _petVaccineBytes == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
  onPressed: () {
    if (_formKey.currentState!.validate()) {
      if (_imageBytes != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm'),
              content: Text('Are you sure you want to save changes?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    setState(() {
                      isLoading = true;
                    });
                    _updateForm().then((_) {
                      setState(() {
                        isLoading = false;
                      });
                    });
                  },
                  child: Text('Yes'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image')),
        );
      }
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: Text('Save Changes', style: TextStyle(color: Colors.white)),
),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetTypeButton(String petType, String assetPath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPetType = petType;
        });
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(petType),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _selectedPetType == petType
                ? Colors.blue.shade100
                : Colors.grey[300],
            border: Border.all(
              color: _selectedPetType == petType
                  ? Colors.blue.shade800
                  : Colors.grey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  assetPath,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error, size: 30),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
