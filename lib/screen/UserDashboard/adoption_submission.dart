import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'view_all_pets.dart';
import '/services/api_services.dart';
import '/services/jwt_storage.dart';
import 'dart:convert';

class AdoptionSubmissionForm extends StatefulWidget {
  final int petId;
  final String petName;
  final int adopterId;

  const AdoptionSubmissionForm(
      {super.key,
      required this.petId,
      required this.petName,
      required this.adopterId});

  @override
  State<AdoptionSubmissionForm> createState() => _AdoptionSubmissionFormState();
}

class _AdoptionSubmissionFormState extends State<AdoptionSubmissionForm> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentPage = 0;

  // Page 1 controllers
  final TextEditingController _altFNameController = TextEditingController();
  final TextEditingController _altLNameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _altContactNumberController =
      TextEditingController();
  final TextEditingController _altEmailController = TextEditingController();
  final TextEditingController _altValidIDController = TextEditingController();
  final TextEditingController _validIDController = TextEditingController();

  // Page 2 controllers
  final TextEditingController _petTypeController = TextEditingController();
  final TextEditingController _shelterAnimalController =
      TextEditingController();
  final TextEditingController _idealPetDescriptionController =
      TextEditingController();
  final TextEditingController _housingSituationController =
      TextEditingController();
  final TextEditingController _petsAtHomeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _familySupportController =
      TextEditingController();
  final TextEditingController _pastPetsController = TextEditingController();

  // Page 3 controllers
  final TextEditingController _interviewSettingController =
      TextEditingController();

  // File states
  List<Map<String, dynamic>> _homeFiles = [];
  List<Map<String, dynamic>> _validIDPhoto = [];
  List<Map<String, dynamic>> _altValidPhoto = [];

  @override
  void dispose() {
    _pageController.dispose();
    _altFNameController.dispose();
    _altLNameController.dispose();
    _relationshipController.dispose();
    _altContactNumberController.dispose();
    _altEmailController.dispose();
    _altValidIDController.dispose();
    _validIDController.dispose();
    _petTypeController.dispose();
    _shelterAnimalController.dispose();
    _idealPetDescriptionController.dispose();
    _housingSituationController.dispose();
    _petsAtHomeController.dispose();
    _allergiesController.dispose();
    _familySupportController.dispose();
    _pastPetsController.dispose();
    _interviewSettingController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles(
      List<Map<String, dynamic>> targetList, int maxCount, String type,
      {List<String>? allowedExtensions}) async {
    if (targetList.length >= maxCount) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result != null) {
      for (var file in result.files) {
        if (targetList.length >= maxCount) break;
        targetList.add({
          'fileName': file.name,
          'bytes': file.bytes!,
          'type': type,
        });
      }
      setState(() {});
    }
  }

  void _removeFile(List<Map<String, dynamic>> targetList, int index) {
    setState(() => targetList.removeAt(index));
  }

  void _nextPage() {
    if (_currentPage < 2 && _formKey.currentState!.validate()) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  bool _isFileTooLarge(List<int> bytes, int maxSizeMB) {
    return bytes.length > maxSizeMB * 1024 * 1024;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await TokenStorage.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    // Validate contact number
    if (_altContactNumberController.text.length < 11 ||
        !RegExp(r'^[0-9]+$').hasMatch(_altContactNumberController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Contact number must be at least 11 digits and contain only numbers')));
      return;
    }

    // Validate email
    if (!_altEmailController.text.contains('@') ||
        !_altEmailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    // Validate file sizes
    for (var file in _homeFiles) {
      if (_isFileTooLarge(file['bytes'], 15)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('One of your home files exceeds 15MB limit')));
        return;
      }
    }

    if (_validIDPhoto.isNotEmpty &&
        _isFileTooLarge(_validIDPhoto[0]['bytes'], 8)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valid ID file exceeds 8MB limit')));
      return;
    }

    if (_altValidPhoto.isNotEmpty &&
        _isFileTooLarge(_altValidPhoto[0]['bytes'], 8)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Alternate Valid ID file exceeds 8MB limit')));
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/submission/${widget.petId}'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields.addAll({
        'altFName': _altFNameController.text,
        'altLName': _altLNameController.text,
        'relationship': _relationshipController.text,
        'altContactNumber': _altContactNumberController.text,
        'altEmail': _altEmailController.text,
        'altValidID': _altValidIDController.text,
        'validID': _validIDController.text,
        'petType': _petTypeController.text,
        'shelterAnimal': _shelterAnimalController.text,
        'idealPetDescription': _idealPetDescriptionController.text,
        'housingSituation': _housingSituationController.text,
        'petsAtHome': _petsAtHomeController.text,
        'allergies': _allergiesController.text,
        'familySupport': _familySupportController.text,
        'pastPets': _pastPetsController.text,
        'interviewSetting': _interviewSettingController.text,
      });

      // Add home files
      for (var file in _homeFiles) {
        request.files.add(http.MultipartFile.fromBytes(
          'homeFiles',
          file['bytes'],
          filename: file['fileName'],
        ));
      }

      // Add valid ID photo
      if (_validIDPhoto.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'validIDPhoto',
          _validIDPhoto[0]['bytes'],
          filename: _validIDPhoto[0]['fileName'],
        ));
      }

      // Add alternate valid ID photo
      if (_altValidPhoto.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'altValidIDPhoto',
          _altValidPhoto[0]['bytes'],
          filename: _altValidPhoto[0]['fileName'],
        ));
      }

      // Send the submission request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Update the pet status to "pending"
        final updateResponse = await http.post(
          Uri.parse('${ApiService.baseUrl}/users/status/${widget.petId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'status': 'pending'}),
        );

        Navigator.pop(context); // Dismiss loading indicator

        if (updateResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Submitted successfully')));

          // Navigate to ViewAllPetsScreen directly
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ViewAllPetsScreen(
                      adopterId: widget.adopterId,
                    )),
          );
        } else {
          final errorMessage =
              jsonDecode(updateResponse.body)['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to update pet status: $errorMessage')));
        }
      } else {
        Navigator.pop(context); // Dismiss loading indicator
        final errorMessage =
            jsonDecode(responseBody)['error'] ?? 'Unknown error';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $errorMessage')));
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading indicator if still showing
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')));
    }
  }

  Widget _buildImagePicker(String label, List<Map<String, dynamic>> fileList,
      int maxCount, String photoType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < fileList.length; i++)
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: fileList[i]['fileName'].toString().endsWith('.pdf')
                        ? const Center(child: Icon(Icons.picture_as_pdf))
                        : Image.memory(fileList[i]['bytes'],
                            width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: -5,
                    top: -5,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeFile(fileList, i),
                    ),
                  ),
                ],
              ),
            if (fileList.length < maxCount)
              GestureDetector(
                onTap: () => _pickFiles(fileList, maxCount, photoType),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPage1() {
    return _buildPageLayout([
      const Text('Alternate Contact Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      TextFormField(
          controller: _altFNameController,
          decoration:
              const InputDecoration(labelText: 'Alternative First Name'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _altLNameController,
          decoration: const InputDecoration(labelText: 'Alternative Last Name'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _relationshipController,
          decoration: const InputDecoration(labelText: 'Relationship'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _altContactNumberController,
          decoration:
              const InputDecoration(labelText: 'Alternative Contact Number'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _altEmailController,
          decoration: const InputDecoration(labelText: 'Alternative Email'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _altValidIDController,
          decoration:
              const InputDecoration(labelText: 'Alternative Valid ID Type'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _validIDController,
          decoration: const InputDecoration(labelText: 'Your Valid ID Type'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
    ], nextOnly: true);
  }

  Widget _buildPage2() {
    return _buildPageLayout([
      const Text('Pet and Household Info',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      TextFormField(
          controller: _petTypeController,
          decoration: const InputDecoration(labelText: 'Pet Type'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _shelterAnimalController,
          decoration: const InputDecoration(
              labelText: 'Have you had a shelter animal before?'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _idealPetDescriptionController,
          decoration:
              const InputDecoration(labelText: 'Describe your ideal pet'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _housingSituationController,
          decoration:
              const InputDecoration(labelText: 'Your Housing Situation'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _petsAtHomeController,
          decoration:
              const InputDecoration(labelText: 'Do you have pets at home?'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _allergiesController,
          decoration:
              const InputDecoration(labelText: 'Any allergies to pets?'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _familySupportController,
          decoration:
              const InputDecoration(labelText: 'Family support for adoption'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      TextFormField(
          controller: _pastPetsController,
          decoration:
              const InputDecoration(labelText: 'Tell us about your past pets'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
    ]);
  }

  Widget _buildPage3() {
    return _buildPageLayout([
      const Text('Interview and Uploads',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      TextFormField(
          controller: _interviewSettingController,
          decoration:
              const InputDecoration(labelText: 'Preferred interview setting'),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Required field' : null),
      _buildImagePicker("Upload House Files (max 15MB total, images or PDFs)",
          _homeFiles, 8, "HousePhoto"),
      _buildImagePicker(
          "Upload Valid ID Photo (max 8MB)", _validIDPhoto, 1, "ValidID"),
      _buildImagePicker("Upload Alt. Valid ID Photo (max 8MB)", _altValidPhoto,
          1, "AltValidID"),
    ], isLast: true);
  }

  Widget _buildPageLayout(List<Widget> fields,
      {bool nextOnly = false, bool isLast = false}) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            ...fields,
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!nextOnly)
                  ElevatedButton(
                      onPressed: _previousPage, child: const Text("Back")),
                ElevatedButton(
                  onPressed: isLast ? _submitForm : _nextPage,
                  child: Text(isLast ? "Submit" : "Next"),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adopt ${widget.petName}"),
        automaticallyImplyLeading: false, // Removes the back arrow
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildPage1(), _buildPage2(), _buildPage3()],
      ),
    );
  }
}
