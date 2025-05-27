import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petData;

  const PetDetailsScreen({super.key, required this.petData});

  void showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7), // Dim background
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(imageBytes),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 250, 255),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        centerTitle: false,
        title: Text('Pet Information',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 75,
                backgroundImage: petData['pet_image1'] != null
                    ? MemoryImage(petData['pet_image1'] as Uint8List)
                    : const AssetImage('assets/images/logo.png')
                        as ImageProvider,
              ),
              const SizedBox(height: 20),

              // Pet Name
              Text(
                petData['pet_name'] ?? 'No Available Data',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Divider
              Divider(color: Colors.grey[400], thickness: 1),
              const SizedBox(height: 10),

              // Pet Details
              _infoRow('Type of Pet', petData['pet_type']),
              const SizedBox(height: 8),
              _infoRow('Sex', petData['pet_sex']),
              const SizedBox(height: 8),
              _infoRow(
                'Age',
                '${petData['pet_age'] ?? 'No Available Data'} ${petData['age_type'] ?? ''}',
              ),
              const SizedBox(height: 8),
              _infoRow(
                  'Size', '${petData['pet_size'] ?? 'No Available Data'} KG'),
              const SizedBox(height: 10),

              // Divider
              Divider(color: Colors.grey[400], thickness: 1),
              const SizedBox(height: 10),

              // Pet Description
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pet Description',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                petData['pet_descriptions'] ?? 'No Available Data',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[400], thickness: 1),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vaccination Image',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (petData['pet_vaccine'] != null) {
                        showFullScreenImage(
                          context,
                          petData['pet_vaccine'],
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: petData['pet_vaccine'] != null
                            ? MemoryImage(petData['pet_vaccine'] as Uint8List)
                            : const AssetImage('assets/images/noimage2.webp')
                                as ImageProvider,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          value ?? 'No Available Data',
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
