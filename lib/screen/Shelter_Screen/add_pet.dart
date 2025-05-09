import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_bar.dart';
import 'view_pets.dart';

class AddPetScreen extends StatefulWidget {
  final int shelterId;

  const AddPetScreen({super.key, required this.shelterId});

  @override
  _AddPetScreenState createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _priorityStatus = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  String? _selectedPetType;
  String? _selectedAgeType;
  String? _selectedSex;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  Uint8List? _petVaccineBytes;
  int _currentPage = 0;
  late AnimationController _progressBarController;

  @override
  void initState() {
    super.initState();
    _progressBarController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _progressBarController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!_formKey.currentState!.validate()) return;

    var uri = Uri.parse(
        "http://127.0.0.1:5566/api/shelter/${widget.shelterId}/add-pet");
    var request = http.MultipartRequest("POST", uri);

    // Add token header
    request.headers['Authorization'] = "Bearer $token";

    // Set fields
    request.fields['pet_type'] = _selectedPetType ?? "";
    request.fields['pet_name'] = _nameController.text;
    request.fields['pet_age'] = _ageController.text;
    request.fields['age_type'] = _selectedAgeType ?? "";
    request.fields['pet_sex'] = _selectedSex ?? "";
    request.fields['pet_size'] = _sizeController.text;
    request.fields['pet_descriptions'] = _descriptionController.text;
    request.fields['priority_status'] = _priorityStatus ? '1' : '0';

    // Attach image if available
    if (_imageBytes != null && _imageFile != null) {
      final fileExtension = _imageFile!.path.split('.').last.toLowerCase();
      request.files.add(
        http.MultipartFile.fromBytes(
          'pet_image1',
          _imageBytes!,
          filename: 'pet_image.$fileExtension',
          contentType: MediaType('image', fileExtension),
        ),
      );
    }

    // Attach image if available
    if (_petVaccineBytes != null && _petVaccineBytes != null) {
      final fileExtension = _imageFile!.path.split('.').last.toLowerCase();
      request.files.add(
        http.MultipartFile.fromBytes(
          'pet_vaccine',
          _imageBytes!,
          filename: 'pet_vaccine.$fileExtension',
          contentType: MediaType('image', fileExtension),
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pet added successfully!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewPetsScreen(shelterId: widget.shelterId),
          ),
        );
      } else {
        // Parse message from backend
        String message = "Failed to add pet";
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) message = body['message'];
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  InputDecoration _buildTextFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Enter pet name';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value))
      return 'Only letters allowed';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Enter pet age';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only numbers allowed';
    return null;
  }

  String? _validateSize(String? value) {
    if (value == null || value.isEmpty) return 'Enter pet size';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value))
      return 'Only numbers allowed';
    return null;
  }

  String? _validateImage() {
    if (_imageBytes == null || _imageFile == null) {
      return 'Please select an image';
    }
    return null;
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

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20), // Spacing between title and avatar
            Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 3; i >= 1; i--)
                  Container(
                    width: 150 + i * 20,
                    height: 150 + i * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.05 * i),
                        width: 1,
                      ),
                    ),
                  ),
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                  child: _imageBytes == null
                      ? Icon(Icons.camera_alt,
                          size: 50, color: Colors.grey[600])
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAdopterValidID() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // Convert to bytes
      setState(() {
        _petVaccineBytes = bytes; // Store the bytes for the image
      });
    }
  }

  Widget _buildpetVaccinePreview() {
    return GestureDetector(
      onTap: _pickAdopterValidID,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pet Vaccine Image"),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
              image: DecorationImage(
                image: _petVaccineBytes != null
                    ? MemoryImage(_petVaccineBytes!) // Use MemoryImage
                    : const AssetImage('assets/images/logo.png')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: _petVaccineBytes == null
                ? const Center(
                    child: Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value,
      {bool isDescription = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: isDescription ? 14 : 16),
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentPage) {
      case 0:
        return Column(
          children: [
            _buildImagePreview(),
            SizedBox(height: 20),
            Text(
              'What type of pet is it?',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPetTypeButton('Dog', 'images/dog.png'),
                SizedBox(width: 30),
                _buildPetTypeButton('Cat', 'images/cat.png'),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'What is the pet name?',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              decoration: _buildTextFieldDecoration('Pet Name'),
              validator: _validateName,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
              ],
            ),
            SizedBox(height: 20),
          ],
        );

      case 1:
        return Column(
          children: [
            _buildImagePreview(),
            SizedBox(height: 20),
            Text(
              '${_nameController.text}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Text(
              'What is the pet age?',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: _buildTextFieldDecoration('Pet Age'),
                    validator: _validateAge,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _buildTextFieldDecoration('Age Type'),
                    value: _selectedAgeType,
                    items: ['Month', 'Year'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAgeType = value),
                    validator: (value) =>
                        value == null ? 'Select age type' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'What is the pet size?',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sizeController,
                    decoration: _buildTextFieldDecoration('Pet Size').copyWith(
                      suffixText: 'KG',
                      suffixStyle: TextStyle(color: Colors.grey[600]),
                    ),
                    validator: _validateSize,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _buildTextFieldDecoration('Pet Sex'),
                    value: _selectedSex,
                    items: ['Male', 'Female'].map((sex) {
                      return DropdownMenuItem(value: sex, child: Text(sex));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSex = value),
                    validator: (value) => value == null ? 'Select a sex' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        );

      case 2:
        return Column(
          children: [
            _buildImagePreview(),
            SizedBox(height: 20),
            Text(
              '${_nameController.text}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Text(
              'Note: You can include details like pet history, traits, etc.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _descriptionController,
              decoration: _buildTextFieldDecoration('Pet Description'),
              maxLines: 3,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a description' : null,
            ),
            SizedBox(height: 20),
            _buildpetVaccinePreview(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority Status',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _priorityStatus,
                  onChanged: (bool value) {
                    setState(() {
                      _priorityStatus = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 25),
          ],
        );

      case 3:
        return Column(
          children: [
            SizedBox(height: 20),
            Text(
              'Review Pet Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (_imageBytes != null)
              CircleAvatar(
                radius: 70,
                backgroundImage: MemoryImage(_imageBytes!),
              ),
            SizedBox(height: 20),
            _buildReviewItem('Pet Type', _selectedPetType ?? 'Not specified'),
            _buildReviewItem('Name', _nameController.text),
            _buildReviewItem('Size', _sizeController.text),
            _buildReviewItem(
                'Age', '${_ageController.text} ${_selectedAgeType ?? ''}'),
            _buildReviewItem('Sex', _selectedSex ?? 'Not specified'),
            _buildReviewItem('Description', _descriptionController.text,
                isDescription: true),
            if (_petVaccineBytes != null)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(_petVaccineBytes!),
                    fit: BoxFit.cover,
                  ),
                  borderRadius:
                      BorderRadius.circular(8), // optional: for slight rounding
                ),
              ),
            _buildReviewItem('Priority Status', _priorityStatus ? 'Yes' : 'No'),
            SizedBox(height: 20),
            Text(
              'Please review all pet information before submitting',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: _currentPage == index ? 14 : 8,
          height: _currentPage == index ? 14 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Colors.blue.shade700
                : Colors.grey.shade400,
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Add Pet',
                      style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {}),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildProgressBar(),
            SizedBox(height: 10),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(child: _buildPageContent()),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPage--;
                            _progressBarController.forward(from: 0);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Back',
                            style:
                                TextStyle(color: Colors.black, fontSize: 16)),
                      ),
                    ),
                  if (_currentPage > 0) SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == 0 && _validateImage() != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_validateImage()!)),
                          );
                          return;
                        }

                        if (_formKey.currentState!.validate()) {
                          if (_currentPage < 3) {
                            setState(() {
                              _currentPage++;
                              _progressBarController.forward(from: 0);
                            });
                          } else {
                            _submitForm();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 55),
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_currentPage < 3 ? 'Next' : 'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
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
