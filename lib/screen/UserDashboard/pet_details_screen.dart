import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petData;

  const PetDetailsScreen({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2F3FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
              // Pet Image
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
