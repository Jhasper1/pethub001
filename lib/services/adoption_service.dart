import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AdoptionService {
  final String baseUrl =
      'http://127.0.0.1:5566 '; // Update with your backend URL

  /// Pick a single image (image_picker)
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Pick multiple files (file_picker)
  Future<List<File>> pickMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      return result.paths.map((path) => File(path!)).toList();
    }
    return [];
  }

  /// Convert file to base64
  Future<String> convertToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Submit Adoption Application
  Future<void> submitAdoptionApplication({
    required String token,
    required int petId,
    required String altFName,
    required String altLName,
    required String relationship,
    required String altContactNumber,
    required String altEmail,
    required String preferredDate,
    required String preferredTime,
    required File housePhoto,
    required File validID,
  }) async {
    final uri = Uri.parse('$baseUrl/adoption/apply/$petId');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['alt_f_name'] = altFName
      ..fields['alt_l_name'] = altLName
      ..fields['relationship'] = relationship
      ..fields['alt_contact_number'] = altContactNumber
      ..fields['alt_email'] = altEmail
      ..fields['preferred_date'] = preferredDate
      ..fields['preferred_time'] = preferredTime
      ..files
          .add(await http.MultipartFile.fromPath('housefile', housePhoto.path))
      ..files.add(await http.MultipartFile.fromPath('valid_id', validID.path));

    final response = await request.send();

    if (response.statusCode == 201) {
      print('✅ Adoption application submitted successfully.');
    } else {
      print(
          '❌ Failed to submit adoption application. Code: ${response.statusCode}');
    }
  }

  /// Submit Questionnaire
  Future<void> submitQuestionnaire({
    required String token,
    required String petType,
    required Map<String, dynamic> formFields,
    required List<File> homePhotos,
    required File? validID,
  }) async {
    final uri = Uri.parse('$baseUrl/adoption/questionnaire');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['pet_type'] = petType;

    // Add all questionnaire fields
    formFields.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add multiple home photos
    for (var photo in homePhotos) {
      request.files
          .add(await http.MultipartFile.fromPath('home_photos', photo.path));
    }

    // Add valid ID
    if (validID != null) {
      request.files
          .add(await http.MultipartFile.fromPath('valid_id', validID.path));
    }

    final response = await request.send();

    if (response.statusCode == 201) {
      print('✅ Questionnaire submitted successfully.');
    } else {
      print('❌ Failed to submit questionnaire. Code: ${response.statusCode}');
    }
  }
}
