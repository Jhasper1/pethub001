import 'dart:convert';
import 'dart:typed_data'; // To handle image bytes

class PetDetailsScreen extends StatefulWidget {
  final int petId;


  @override
  _PetDetailsScreenState createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPetDetails();
  }

  Future<void> fetchPetDetails() async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {

          setState(() {
          });
      } else {
        throw Exception('Failed to load pet data');
      }
    } catch (e) {
      print("Error fetching pet data: $e");
      setState(() {
        errorMessage = "Error fetching pet data.";
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          as ImageProvider,
                        ),
                        Text(
                        ),
                      ],
                    ),
                  ),
                    'Pet Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                        'No description available.',
                    textAlign: TextAlign.justify,
                  ),
                  Divider(thickness: 1, color: Colors.grey[400]),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                ],
    );
  }
}