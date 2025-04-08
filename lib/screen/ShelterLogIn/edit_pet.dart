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

  String? _selectedPetType;
  String? _selectedAgeType;
  String? _selectedSex;
  Uint8List? _imageBytes;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    final url = 'http://127.0.0.1:5566/shelter/${widget.petId}/petinfo';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data");

        final petDataResponse = data['data']['pet'];

        setState(() {
          _nameController.text = petDataResponse['pet_name'] ?? '';
          _ageController.text = petDataResponse['pet_age'].toString();
          _descriptionController.text =
              petDataResponse['pet_descriptions'] ?? '';
          _selectedAgeType = petDataResponse['age_type'];
          _selectedSex = petDataResponse['pet_sex'];
          _selectedPetType = petDataResponse['pet_type'];

          // Decode image if available
          if (petDataResponse['pet_image1'] != null &&
              petDataResponse['pet_image1'].isNotEmpty) {
            _imageBytes = base64Decode(petDataResponse['pet_image1'][0]);
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
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _updateForm() async {
  final url = Uri.parse(
      'http://127.0.0.1:5566/shelter/${widget.petId}/update-pet-info');

  // Ensure image is properly encoded to Base64 only if image exists
  final petMedia = {
  "pet_image1": _imageBytes != null && _imageBytes!.isNotEmpty
      ? base64Encode(_imageBytes!)
      : "",
};


  final body = {
    "pet_info": {
      "pet_name": _nameController.text,
      "pet_age": int.tryParse(_ageController.text) ?? 0,
      "age_type": _selectedAgeType,
      "pet_sex": _selectedSex,
      "pet_type": _selectedPetType,
      "pet_descriptions": _descriptionController.text,
    },
    "pet_image1": petMedia['pet_image1'],
  };

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
      Navigator.pop(context, true); // send a result back
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

            bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 1,
      ),
      appBar: AppBar(title: Text('Edit Pet')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : const AssetImage('assets/images/logo.png')
                                    as ImageProvider,
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.camera_alt,
                                    size: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'What type of pet is it?',
                        style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600]),
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPetTypeButton('Dog'),
                          SizedBox(width: 10),
                          _buildPetTypeButton('Cat'),
                        ],
                      ),
                      SizedBox(height: 15),
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
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: _buildTextFieldDecoration('Pet Age'),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter age'
                                  : null,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAgeType,
                              decoration: _buildTextFieldDecoration('Age Type'),
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
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedSex,
                        decoration: _buildTextFieldDecoration('Pet Sex'),
                        items: ['Male', 'Female'].map((val) {
                          return DropdownMenuItem(value: val, child: Text(val));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSex = val);
                        },
                        validator: (val) => val == null ? 'Select sex' : null,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Note: Add any details about the pet like behavior, health, etc.',
                        style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600]),
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 6,
                        decoration:
                            _buildTextFieldDecoration('Pet Description'),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Enter description'
                            : null,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_imageBytes != null) {
                              setState(() {
                                isLoading = true;
                              });
                              _updateForm().then((_) {
                                setState(() {
                                  isLoading = false;
                                });
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Please select an image')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Save updates',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPetTypeButton(String type) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedPetType = type),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selectedPetType == type ? Colors.orange : Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(type, style: TextStyle(color: Colors.white)),
    );
  }
}
