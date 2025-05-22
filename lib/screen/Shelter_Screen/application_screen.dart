import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:march24/screen/Shelter_Screen/pending_adoption_screen.dart';
import 'bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'application_details_screen.dart'; // Import the details screen

class ApplicantsScreen extends StatefulWidget {
  final int shelterId;

  const ApplicantsScreen({super.key, required this.shelterId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  String selectedSort = 'Newest';
  final List<String> sortOptions = ['Newest', 'Oldest', 'A to Z', 'Z to A'];

  String selectedTab = 'Interview';
  final List<String> tabs =
      ['Interview', 'Passed', 'Adopted', 'Rejected'].toList();
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = false;

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'No date';
    final dateTime = DateTime.parse(rawDate).toLocal();
    final formatter = DateFormat('MMM d, y');
    return formatter.format(dateTime);
  }

  String formatTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return 'No time';
    final time = DateFormat.Hms().parse(rawTime);
    return DateFormat.jm().format(time);
  }

  String formatUpdatedAt(String? rawDateTime) {
    if (rawDateTime == null || rawDateTime.isEmpty) return 'No date';
    final dateTime = DateTime.parse(rawDateTime);
    return DateFormat("MMM d, y - h:mm a").format(dateTime.toLocal());
  }

  @override
  void initState() {
    super.initState();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final status = selectedTab.toLowerCase();
    final url =
        'http://127.0.0.1:5566/api/shelter/${widget.shelterId}/adoption-applications?status=$status';

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded != null &&
            decoded is Map &&
            decoded.containsKey('data') &&
            decoded['data'] is Map &&
            decoded['data'].containsKey('submissions') &&
            decoded['data']['submissions'] is List) {
          final List applicationList = decoded['data']['submissions'];
          print('Fetched ${applicationList.length} applicants');

          final updatedApplicants =
              applicationList.map((app) => _mapApplicant(app)).toList();

          // Sort the applicants list after mapping
          updatedApplicants.sort((a, b) {
            DateTime dateA =
                DateTime.tryParse(a['created_at']) ?? DateTime(2000);
            DateTime dateB =
                DateTime.tryParse(b['created_at']) ?? DateTime(2000);

            if (selectedSort == 'A to Z') {
              return a['first_name']
                  .toString()
                  .toLowerCase()
                  .compareTo(b['first_name'].toString().toLowerCase());
            } else if (selectedSort == 'Z to A') {
              return b['first_name']
                  .toString()
                  .toLowerCase()
                  .compareTo(a['first_name'].toString().toLowerCase());
            } else if (selectedSort == 'Newest') {
              return dateB.compareTo(dateA);
            } else if (selectedSort == 'Oldest') {
              return dateA.compareTo(dateB);
            } else {
              return 0;
            }
          });

          setState(() {
            applicants = updatedApplicants;
            isLoading = false;
          });
        } else {
          setState(() {
            applicants = [];
            isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          applicants = [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load applicants')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Map<String, dynamic> _mapApplicant(dynamic app) {
    final adopter = app['adopter'] ?? {};
    final adopterMedia = adopter['adoptermedia'] ?? {};
    final pet = app['pet'] ?? {};
    final scheduleInterview = app['scheduleinterview'];

    bool hasInterview = scheduleInterview != null &&
        scheduleInterview['application_id'] != null;

    return {
      'application_id': app['application_id'] ?? '',
      'first_name': adopter['first_name']?.toString() ?? '',
      'last_name': adopter['last_name']?.toString() ?? '',
      'adopter_profile': adopterMedia['adopter_profile']?.toString() ?? '',
      'pet_name': pet['pet_name']?.toString() ?? '',
      'status': app['status']?.toString() ?? '',
      'reason_for_rejection': app['reason_for_rejection']?.toString() ?? '',
      'created_at': app['created_at']?.toString() ?? '',
      'updated_at': app['updated_at']?.toString() ?? '',
      'has_interview': hasInterview,
      'interview_date':
          hasInterview ? scheduleInterview['interview_date']?.toString() : null,
      'interview_time':
          hasInterview ? scheduleInterview['interview_time']?.toString() : null,
      'interview_notes': hasInterview
          ? scheduleInterview['interview_notes']?.toString() ?? ''
          : '',
      'adopter_profile_decoded':
          _decodeBase64Image(adopterMedia['adopter_profile']?.toString()),
    };
  }

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null; // If the string is null or empty, return null
    }
    try {
      final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
      base64String = base64String.replaceAll(regex, '');
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding Base64 image: $e");
      return null;
    }
  }

  // Function to handle tab selection
  void onTabSelected(String tab) {
    setState(() {
      selectedTab = tab;
    });
    fetchApplicants(); // Re-fetch applicants based on the new status
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavBar(
        shelterId: widget.shelterId,
        currentIndex: 3,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PendingApplicantsScreen(shelterId: widget.shelterId),
            ),
          );
        },
        icon: const Icon(Icons.assignment, color: Colors.white),
        label: Text('New Applications',
            style: GoogleFonts.poppins(
              color: Colors.white,
            )),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                      'Adoptions',
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
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${applicants.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedTab,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedTab = value;
                          });
                          fetchApplicants();
                        }
                      },
                      items: tabs.map((tab) {
                        return DropdownMenuItem(
                          value: tab,
                          child: Text(tab, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 14),
                      icon: const Icon(Icons.arrow_drop_down),
                      underline: Container(height: 2, color: Colors.lightBlue),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedSort,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSort = value;
                          });
                          fetchApplicants();
                        }
                      },
                      items: sortOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 14),
                      icon: const Icon(Icons.sort),
                      underline: Container(height: 2, color: Colors.lightBlue),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Here is the list of applications:",
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : applicants.isEmpty
                      ? Center(
                          child: Text('No applications found.',
                              style: GoogleFonts.poppins()))
                      : ListView.builder(
                          itemCount: applicants.length,
                          itemBuilder: (context, index) {
                            final applicant = applicants[index];
                            return GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ApplicationDetailsScreen(
                                      applicationId:
                                          applicant['application_id'],
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  fetchApplicants(); // refresh the list when coming back
                                }
                              },
                              child: Card(
                                color: const Color.fromARGB(255, 239, 250, 255),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundImage: applicant[
                                                        'adopter_profile_decoded'] !=
                                                    null
                                                ? MemoryImage(applicant[
                                                    'adopter_profile_decoded'])
                                                : const AssetImage(
                                                        'assets/images/logo.png')
                                                    as ImageProvider,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${applicant['first_name']} ${applicant['last_name']}',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Chosen Pet: ${applicant['pet_name']}',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (applicant['has_interview'] &&
                                          applicant['interview_time'] != null &&
                                          applicant['interview_date'] != null &&
                                          applicant['status'] != 'rejected' &&
                                          applicant['status'] != 'passed' &&
                                          applicant['status'] != 'adopted') ...[
                                        Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.schedule,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${formatTime(applicant['interview_time'])} | ${formatDate(applicant['interview_date'])}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 17),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (applicant['status'] == 'adopted') ...[
                                        Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Adopted on:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.schedule,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formatUpdatedAt(
                                                      applicant['updated_at']),
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 17),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      if (applicant['status'] == 'passed' ||
                                          applicant['status'] == 'adopted') ...[
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              generateAndShowAgreementPDF();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.lightBlue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              minimumSize: const Size(
                                                  double.infinity, 50),
                                            ),
                                            child: Text(
                                              'Download Agreement',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors
                                                    .white, // optional: since the button is white
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (applicant['status'] == 'interview' ||
                                          applicant['status'] == 'rejected')
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.push_pin,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                applicant['status'] ==
                                                        'interview'
                                                    ? Text(
                                                        'Interview Notes:',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      )
                                                    : const SizedBox(),
                                                applicant['status'] ==
                                                        'rejected'
                                                    ? Text(
                                                        'Reason for Rejection:',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      )
                                                    : const SizedBox(),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          applicant['status'] ==
                                                                  'rejected'
                                                              ? Colors.red[100]
                                                              : Colors
                                                                  .yellow[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      applicant['status'] ==
                                                              'rejected'
                                                          ? applicant[
                                                                  'reason_for_rejection'] ??
                                                              'N/A'
                                                          : applicant[
                                                                  'interview_notes'] ??
                                                              'N/A',
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> generateAndShowAgreementPDF() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final applicationId = int.parse(applicants[0]['application_id'].toString());

    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:5566/api/shelter/export/${widget.shelterId}/$applicationId/letter'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      print('Failed to fetch adoption application');
      return;
    }

    final responseData = jsonDecode(response.body);
    final info = responseData['data'];

    final adopterName =
        // ignore: prefer_interpolation_to_compose_strings
        info['adopter']['first_name'] + ' ' + info['adopter']['last_name'];
    final adopterAddress = info['adopter']['address'];
    final petName = info['pet']['pet_name'];
    final petType = info['pet']['pet_type'];
    final petGender = info['pet']['pet_sex'];

    final shelterName = info['shelter']['shelter_name'];
    final shelterAddress = info['shelter']['shelter_address'];
    final shelterPhone =
        info['shelter']['shelter_contact']; // fixed key name from your JSON
    final shelterEmail = info['shelter']['shelter_email'];

    final pdf = pw.Document();

    pw.Widget buildUnderlinedText(String text) {
      return pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          decoration: pw.TextDecoration.underline,
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat(8.5 * PdfPageFormat.inch, 14 * PdfPageFormat.inch),
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              shelterName.toUpperCase(),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            buildUnderlinedText(shelterAddress.toUpperCase()),
            pw.SizedBox(height: 4),
            buildUnderlinedText('Contact: $shelterPhone'.toUpperCase()),
            pw.SizedBox(height: 4),
            buildUnderlinedText('Email: $shelterEmail'.toUpperCase()),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'PET ADOPTION AGREEMENT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}",
              textAlign: pw.TextAlign.right,
            ),
            pw.SizedBox(height: 20),
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(children: [
                pw.TextSpan(
                    text: 'This agreement is entered into by and between '),
                pw.TextSpan(
                  text: shelterName.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: ', located at '),
                pw.TextSpan(
                  text: shelterAddress.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: ', represented by '),
                pw.TextSpan(
                  text: '________________________',
                ),
                pw.TextSpan(text: ', and '),
                pw.TextSpan(
                  text: adopterName.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: ', residing at '),
                pw.TextSpan(
                  text: adopterAddress.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: ', regarding the adoption of the pet named '),
                pw.TextSpan(
                  text: petName.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: ', a '),
                pw.TextSpan(
                  text: petType.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: ', sex: '),
                pw.TextSpan(
                  text: petGender.toUpperCase(),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline),
                ),
                pw.TextSpan(text: '.'),
              ]),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Purpose of the Agreement:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                'This agreement ensures that the adopted pet is placed in a responsible, caring, and safe environment.'),
            pw.SizedBox(height: 10),
            pw.Text('Terms and Conditions:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('1. Responsibilities of the Adopter:'),
            pw.Bullet(
                text:
                    'Will provide the pet with proper food, clean water, shelter, and medical attention when needed.'),
            pw.Bullet(
                text:
                    'Will not sell, give away, or abandon the pet without notifying the shelter.'),
            pw.Bullet(
                text:
                    'Will ensure the pet receives regular veterinary care, including vaccinations.'),
            pw.Bullet(
                text:
                    'Will not harm, abuse, neglect, or restrain the pet in any way that endangers its well-being.'),
            pw.SizedBox(height: 10),
            pw.Text('2. Responsibilities of the Shelter:'),
            pw.Bullet(
                text:
                    'Has provided accurate information regarding the pet’s health and background.'),
            pw.Bullet(
                text:
                    'Ensures the pet is in good condition at the time of adoption.'),
            pw.Bullet(
                text:
                    "May follow up or contact the adopter to check on the pet’s condition after adoption."),
            pw.SizedBox(height: 10),
            pw.Text('3. Right to Reclaim:'),
            pw.Bullet(
                text:
                    'If the adopter is found to be violating any part of this agreement, the shelter reserves the right to reclaim the pet.'),
            pw.SizedBox(height: 10),
            pw.Text('4. Voluntary Agreement:'),
            pw.Bullet(
                text:
                    'Both parties confirm that this agreement is made willingly, without pressure or coercion, and with full understanding of the terms.'),
            pw.SizedBox(height: 20),
            pw.Text(
              'IN WITNESS WHEREOF, the parties hereunto set their hands on this agreement on this day.',
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 40),
            pw.Text('Adopter:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(adopterName.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.Text('_________________________'),
                  pw.Text('Signature over Printed Name'),
                ],
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Text('Shelter Representative:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('_________________________'),
                  pw.Text('Signature over Printed Name'),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
