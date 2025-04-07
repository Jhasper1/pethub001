import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import 'bottom_nav_bar.dart';
import 'pet_info_screen.dart';

class EditPetScreen extends StatefulWidget {
  final int petId;
  final int shelterId; // Add shelterId as a parameter

  const EditPetScreen(
      {super.key, required this.petId, required this.shelterId});

  @override
  _EditPetScreenState createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedPetType;
  String? _selectedAgeType;
  String? _selectedSex;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool isLoading = true;
  String errorMessage = '';

  Future<void> fetchPetDetails() async {
    final url = 'http://127.0.0.1:5566/shelter/${widget.petId}/petinfo';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final petDataResponse = data['data']['pet'];

        setState(() {
          _nameController.text = petDataResponse['pet_name'] ?? '';
          _ageController.text = petDataResponse['pet_age']?.toString() ?? '';
          _descriptionController.text =
              petDataResponse['pet_descriptions'] ?? '';
          _selectedPetType = petDataResponse['pet_type'];
          _selectedSex = petDataResponse['pet_sex'];
          _selectedAgeType = petDataResponse['age_type'];

          var imageData = petDataResponse['pet_image1'];

          if (imageData != null) {
            if (imageData is String) {
              _imageBytes = base64Decode(imageData);
            } else if (imageData is List) {
              _imageBytes = Uint8List.fromList(List<int>.from(imageData));
            }
          }

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pet data');
      }
    } catch (e) {
      print("Error fetching pet data: $e");
      setState(() {
        errorMessage = "Error fetching pet data.";
        isLoading = false;
      });
    }
  }

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

  Future<void> _updateForm() async {
    final url = Uri.parse(
        'http://127.0.0.1:5566/shelter/${widget.petId}/update-pet-info');

    String? base64Image;
    if (_imageBytes != null) {
      base64Image = base64Encode(_imageBytes!);
    }

    final Map<String, dynamic> body = {
  "pet_info": {
    "pet_name": _nameController.text,
    "pet_age": int.tryParse(_ageController.text) ?? 0,  // Ensure pet_age is an integer
    "age_type": _selectedAgeType,
    "pet_sex": _selectedSex,
    "pet_type": _selectedPetType,
    "pet_descriptions": _descriptionController.text,
  },
  "pet_media": {
    "pet_image1": base64Image ?? "",
  },
};
    print("Request Body: $body"); // Debugging

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        print('Failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update pet.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter pet name';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Only letters allowed';
    }
    return null;
  }

  String? _validateAge(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter pet age';
  }
  if (int.tryParse(value) == null) {
    return 'Enter a valid age';
  }
  return null;
}


  String? _validatePetType(String? value) {
    if (value == null) {
      return 'Select a pet type';
    }
    return null;
  }

  String? _validateImage() {
    if (_imageBytes == null || _imageFile == null) {
      return 'Please select an image';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
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
                Text(
                  'What type of pet is it?',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPetTypeButton('Dog', Icons.pets),
                    SizedBox(width: 20),
                    _buildPetTypeButton('Cat', Icons.pets),
                  ],
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildTextFieldDecoration('Pet Name'),
                  validator: _validateName,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: _buildTextFieldDecoration('Pet Age'),
                        validator: _validateAge,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
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
                Text(
                  'Note: You can include details like pet history, traits, etc.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _buildTextFieldDecoration('Pet Description'),
                  maxLines: 6,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter a description' : null,
                ),
                SizedBox(height: 5),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _validateImage() == null) {
                      _updateForm();
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
        currentIndex: 2,
      ),
    );
  }

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
