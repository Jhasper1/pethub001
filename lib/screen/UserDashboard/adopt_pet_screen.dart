import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdoptPetScreen extends StatefulWidget {
  final int petId;
  final String petName;

  AdoptPetScreen({required this.petId, required this.petName});

  @override
  _AdoptPetScreenState createState() => _AdoptPetScreenState();
}

class _AdoptPetScreenState extends State<AdoptPetScreen> {
  final _formKey = GlobalKey<FormState>();

  String? firstName, lastName, address, phone, email, occupation, socialMedia, civilStatus, sex;
  DateTime? birthdate;
  String? adoptedBefore, idealPet, buildingType, rentStatus, movePlan, livingWith, allergy, petCare, petNeeds, vacationPlan, familySupport, otherPets, pastPets;
  String? homePhotos, idUpload, zoomDate, zoomTime, visitShelter;

  final List<String> civilStatuses = ["Single", "Married", "Divorced", "Widowed"];
  final List<String> sexes = ["Male", "Female", "Other"];

  // For Yes/No questions
  String? hasAdoptedBefore, isAllergicToAnimals, hasOtherPets, hasPastPets, familySupportAnswer, canVisitShelter;

  final DateFormat _dateFormat = DateFormat("yyyy-MM-dd");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Adopt ${widget.petName}")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Adoption Form for ${widget.petName}",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                // Applicant's Info Section
                Text("Applicant's Info", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildTextField("Firstname", (value) => firstName = value),
                _buildTextField("Lastname", (value) => lastName = value),
                _buildTextField("Address", (value) => address = value),
                _buildTextField("Phone", (value) => phone = value, inputType: TextInputType.phone, validator: _phoneValidator),
                _buildTextField("Email", (value) => email = value, validator: _emailValidator),
                _buildTextField("Occupation", (value) => occupation = value),
                _buildTextField("Social media profile", (value) => socialMedia = value),

                // Civil Status and Sex Selection
                _buildDropdown("Civil Status", civilStatuses, (value) => civilStatus = value),
                _buildDropdown("Sex", sexes, (value) => sex = value),

                // Birthdate
                _buildDatePicker("Birthdate", (value) => birthdate = value),

                // Have you adopted animals before (Yes/No)
                _buildRadioGroup("Have you adopted animals before?", ["Yes", "No"], hasAdoptedBefore, (value) {
                  setState(() {
                    hasAdoptedBefore = value;
                  });
                }),

                SizedBox(height: 20),

                // Questionnaire Section
                Text("Questionnaire", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildRadioGroup("What are you looking to adopt?", ["Cat", "Dog", "Both", "Not Decided"], idealPet, (value) {
                  setState(() {
                    idealPet = value;
                  });
                }),
                _buildRadioGroup("Are you applying to adopt a specific shelter animal?", ["Yes", "No"], adoptedBefore, (value) {
                  setState(() {
                    adoptedBefore = value;
                  });
                }),
                _buildTextField("Describe your ideal pet, including its sex, age, appearance, temperament, etc.", (value) => idealPet = value),
                _buildTextField("What type of building do you live in?", (value) => buildingType = value),
                _buildRadioGroup("Do you rent?", ["Yes", "No"], rentStatus, (value) {
                  setState(() {
                    rentStatus = value;
                  });
                }),
                _buildRadioGroup("What happens to your pet if or when you move?", ["Take it with me", "Leave it behind", "Other"], movePlan, (value) {
                  setState(() {
                    movePlan = value;
                  });
                }),
                _buildRadioGroup("Who do you live with?", ["Living alone", "Spouse", "Parents", "Children over 18", "Children below 18", "Relatives", "Roommates"], livingWith, (value) {
                  setState(() {
                    livingWith = value;
                  });
                }),
                _buildRadioGroup("Are any members of your household allergic to animals?", ["Yes", "No"], allergy, (value) {
                  setState(() {
                    allergy = value;
                  });
                }),
                _buildTextField("Who will be responsible for feeding, grooming, and generally caring for your pet?", (value) => petCare = value),
                _buildTextField("Who will be responsible for your pet’s needs (food, vet bills, etc)?", (value) => petNeeds = value),
                _buildTextField("Who will look after your pet if you go on vacation or in case of emergency?", (value) => vacationPlan = value),
                _buildTextField("How many hours in an average workday will your pet be left alone?", (value) => vacationPlan = value),
                _buildTextField("What steps will you take to introduce your new pet to his/her new surroundings?", (value) => vacationPlan = value),
                _buildRadioGroup("Does everyone in the family support your decision to adopt a pet?", ["Yes", "No"], familySupportAnswer, (value) {
                  setState(() {
                    familySupportAnswer = value;
                  });
                }),
                _buildRadioGroup("Do you have other pets?", ["Yes", "No"], hasOtherPets, (value) {
                  setState(() {
                    hasOtherPets = value;
                  });
                }),
                _buildRadioGroup("Have you had pets in the past?", ["Yes", "No"], hasPastPets, (value) {
                  setState(() {
                    hasPastPets = value;
                  });
                }),

                SizedBox(height: 20),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Submit Request",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved, {TextInputType inputType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: inputType,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) => onSaved(value),
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDatePicker(String label, Function(DateTime?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? selectedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (selectedDate != null) {
            onSaved(selectedDate);
          }
        },
        controller: TextEditingController(text: birthdate != null ? _dateFormat.format(birthdate!) : ''),
        validator: (value) => value!.isEmpty ? "Please select a birthdate" : null,
      ),
    );
  }

  Widget _buildRadioGroup(String label, List<String> options, String? groupValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ...options.map((String option) {
            return Row(
              children: [
                Radio<String>(
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
                Text(option),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your phone number";
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return "Phone number should only contain numbers";
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email address";
    }
    if (!value.endsWith('@gmail.com')) {
      return "Email must end with @gmail.com";
    }
    return null;
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Adoption request submitted for ${widget.petName}!")),
      );
      Navigator.pop(context);
    }
  }
}
