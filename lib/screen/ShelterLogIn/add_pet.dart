import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import 'bottom_nav_bar.dart';
import 'view_pets.dart';

class AddPetScreen extends StatefulWidget {
  final int shelterId;

  const AddPetScreen({super.key, required this.shelterId});

  @override
  _AddPetScreenState createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedPetType;
  String? _selectedAgeType;
  String? _selectedSex;
  XFile? _imageFile;
  Uint8List? _imageBytes;

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  // Function to submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    var uri = Uri.parse(
        "http://127.0.0.1:5566/shelter/${widget.shelterId}/add-pet-info");

    var request = http.MultipartRequest("POST", uri);
    request.fields['pet_type'] = _selectedPetType ?? "";
    request.fields['pet_name'] = _nameController.text;
    request.fields['pet_age'] = _ageController.text;
    request.fields['age_type'] = _selectedAgeType ?? "";
    request.fields['pet_sex'] = _selectedSex ?? "";
    request.fields['pet_descriptions'] = _descriptionController.text;

    if (_imageBytes != null && _imageFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'pet_image1',
          _imageBytes!,
          filename: _imageFile!.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    var response = await request.send();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pet added successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewPetsScreen(shelterId: widget.shelterId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add pet")),
      );
    }
  }

  // TextField style to be reused
  InputDecoration _buildTextFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  // Name Validation (Only Letters)
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter pet name';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Only letters allowed';
    }
    return null;
  }

  // Age Validation (Only Numbers)
  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter pet age';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Only numbers allowed';
    }
    return null;
  }

  // Pet Type Validation
  String? _validatePetType(String? value) {
    if (value == null) {
      return 'Select a pet type';
    }
    return null;
  }

  // Image Validation
  String? _validateImage() {
    if (_imageBytes == null || _imageFile == null) {
      return 'Please select an image';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Pet')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Image
                GestureDetector(
                  onTap: _pickImage,
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_imageBytes!,
                              height: 150, fit: BoxFit.cover),
                        )
                      : Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.image,
                              size: 50, color: Colors.grey[600]),
                        ),
                ),
                SizedBox(height: 15),

                // Pet Type Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPetTypeButton('Dog', Icons.pets),
                    SizedBox(width: 20),
                    _buildPetTypeButton('Cat', Icons.pets),
                  ],
                ),
                SizedBox(height: 15),

                // Pet Name TextField
                TextFormField(
                  controller: _nameController,
                  decoration: _buildTextFieldDecoration('Pet Name'),
                  validator: _validateName,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z\s]')) // Allow only letters and spaces
                  ],
                ),
                SizedBox(height: 15),

                // Pet Age and Age Type Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: _buildTextFieldDecoration('Pet Age'),
                        validator: _validateAge,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly, // Allow only numbers
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _buildTextFieldDecoration('Age Type'),
                        value: _selectedAgeType,
                        items: ['Month', 'Year'].map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAgeType = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Select an age type' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                // Pet Sex Dropdown
                DropdownButtonFormField<String>(
                  decoration: _buildTextFieldDecoration('Pet Sex'),
                  value: _selectedSex,
                  items: ['Male', 'Female'].map((sex) {
                    return DropdownMenuItem(value: sex, child: Text(sex));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSex = value;
                    });
                  },
                  validator: (value) => value == null ? 'Select a sex' : null,
                ),
                SizedBox(height: 15),

                // Pet Description TextField
                TextFormField(
                  controller: _descriptionController,
                  decoration: _buildTextFieldDecoration('Pet Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter a description' : null,
                ),
                SizedBox(height: 5),

                // Note Below Pet Description
                Text(
                  'Note: You can include details like pet history, traits, etc.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 10),

                // Add Pet Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _validateImage() == null) {
                      _submitForm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Add Pet', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 2, // Index for ViewPetScreen
      ),
    );
  }

  // Pet Type Button
  Widget _buildPetTypeButton(String text, IconData icon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selectedPetType == text ? Colors.orange : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () {
        setState(() {
          _selectedPetType = text;
        });
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: TextStyle(color: Colors.white)),
    );
  }
}
