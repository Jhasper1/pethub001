import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

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

  var uri = Uri.parse("http://127.0.0.1:5566/shelter/${widget.shelterId}/add-pet-info");

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
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Pet Type'),
                  value: _selectedPetType,
                  items: ['Dog', 'Cat'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPetType = value;
                    });
                  },
                  validator: (value) => value == null ? 'Select a pet type' : null,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Pet Name'),
                  validator: (value) => value!.isEmpty ? 'Enter pet name' : null,
                ),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Pet Age'),
                  validator: (value) => value!.isEmpty ? 'Enter pet age' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Age Type'),
                  value: _selectedAgeType,
                  items: ['Months', 'Years'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAgeType = value;
                    });
                  },
                  validator: (value) => value == null ? 'Select an age type' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Pet Sex'),
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
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Enter a description' : null,
                ),
                SizedBox(height: 10),
                // Image Preview and Change on Click
                GestureDetector(
                  onTap: _pickImage,
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_imageBytes!, height: 150, fit: BoxFit.cover),
                        )
                      : Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                        ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Add Pet'),
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
}
