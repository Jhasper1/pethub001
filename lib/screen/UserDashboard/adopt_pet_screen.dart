import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class QuestionnaireScreen extends StatefulWidget {
  final int petId;
  final String petName;

  const QuestionnaireScreen({
    required this.petId,
    required this.petName,
    Key? key,
  }) : super(key: key);

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idealPetDescController = TextEditingController();
  final TextEditingController _petMovePlanController = TextEditingController();
  final TextEditingController _householdCompController = TextEditingController();
  final TextEditingController _careRespController = TextEditingController();
  final TextEditingController _finRespController = TextEditingController();
  final TextEditingController _vacationPlanController = TextEditingController();
  final TextEditingController _aloneTimeController = TextEditingController();
  final TextEditingController _introPlanController = TextEditingController();
  final TextEditingController _familySupportExpController = TextEditingController();
  final TextEditingController _prefInterviewController = TextEditingController();

  List<File> _homePhotos = [];
  File? _validIdFile;
  bool? _specificShelterAnimal;
  String? _buildingType;
  bool? _rent;
  bool? _allergies;
  bool? _familySupport;
  bool? _otherPets;
  bool? _pastPets;
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked != null) {
      setState(() {
        _homePhotos = picked.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _pickValidId() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _validIdFile = File(picked.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final uri = Uri.parse("http://127.0.0.1:5566/questionnaires");
    var request = http.MultipartRequest('POST', uri);

    // Add text fields
    request.fields.addAll({
      'application_id': widget.petId.toString(),
      'pet_type': widget.petName,
      'specific_shelter_animal': _specificShelterAnimal.toString(),
      'ideal_pet_description': _idealPetDescController.text,
      'building_type': _buildingType ?? '',
      'rent': _rent.toString(),
      'pet_move_plan': _petMovePlanController.text,
      'household_composition': _householdCompController.text,
      'allergies_to_animals': _allergies.toString(),
      'care_responsibility': _careRespController.text,
      'financial_responsibility': _finRespController.text,
      'vacation_care_plan': _vacationPlanController.text,
      'alone_time': _aloneTimeController.text,
      'introduction_plan': _introPlanController.text,
      'family_support': _familySupport.toString(),
      'family_support_explanation': _familySupportExpController.text,
      'other_pets': _otherPets.toString(),
      'past_pets': _pastPets.toString(),
      'preferred_interview_setting': _prefInterviewController.text,
    });

    // Add home photos
    for (var photo in _homePhotos) {
      request.files.add(await http.MultipartFile.fromPath(
        'home_photos',
        photo.path,
        filename: path.basename(photo.path),
      ));
    }

    // Add valid ID
    if (_validIdFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'valid_id',
        _validIdFile!.path,
        filename: path.basename(_validIdFile!.path),
      ));
    }

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questionnaire submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${jsonDecode(body)['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildYesNoRadio(String title, bool? value, Function(bool?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: value,
              onChanged: onChanged,
            ),
            Text('Yes'),
            const SizedBox(width: 16),
            Radio<bool>(
              value: false,
              groupValue: value,
              onChanged: onChanged,
            ),
            Text('No'),
          ],
        ),
      ],
    );
  }

  Widget _buildBuildingTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _buildingType,
      decoration: InputDecoration(labelText: 'Building Type'),
      items: ['House', 'Apartment', 'Condo', 'Townhouse', 'Other']
          .map((type) => DropdownMenuItem(
        value: type,
        child: Text(type),
      ))
          .toList(),
      onChanged: (value) => setState(() => _buildingType = value),
      validator: (value) => value == null ? 'Please select' : null,
    );
  }

  Widget _buildImagePreview(List<File> images) {
    if (images.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected Photos:', style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.file(images[index], width: 100, height: 100, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adoption Questionnaire for ${widget.petName}'),
      ),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About Your Living Situation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildYesNoRadio(
                'Are you interested in a specific shelter animal?',
                _specificShelterAnimal,
                    (v) => setState(() => _specificShelterAnimal = v),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _idealPetDescController,
                decoration: InputDecoration(labelText: 'Describe your ideal pet'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              _buildBuildingTypeDropdown(),
              SizedBox(height: 16),
              _buildYesNoRadio(
                'Do you rent your home?',
                _rent,
                    (v) => setState(() => _rent = v),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _petMovePlanController,
                decoration: InputDecoration(labelText: 'What would you do if you had to move?'),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 24),

              // Rest of your form fields...
              // (Include all the other form sections from the previous implementation)

              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Submit Questionnaire', style: TextStyle(fontSize: 18)),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}