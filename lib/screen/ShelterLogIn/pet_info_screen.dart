import 'package:flutter/material.dart';

class PetDetailsScreen extends StatelessWidget {
  final int petId;

  const PetDetailsScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pet Details"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Text(
          "Displaying details for pet ID: $petId",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
