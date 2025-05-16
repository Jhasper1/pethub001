import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdopterNotificationScreen extends StatefulWidget {
  const AdopterNotificationScreen({super.key});

  @override
  State<AdopterNotificationScreen> createState() =>
      _AdopterNotificationScreenState();
}

class _AdopterNotificationScreenState extends State<AdopterNotificationScreen> {
  String? _authToken;
  int? _adopterId;
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeAuthAndFetch();
  }

  Future<void> _initializeAuthAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Print all keys and values in SharedPreferences
      for (var key in prefs.getKeys()) {
        debugPrint('SharedPreferences: $key = ${prefs.get(key)}');
      }

      final token = prefs.getString('auth_token');
      final adopterId = prefs.getInt('adopter_id');

      debugPrint('Fetched token: $token');
      debugPrint('Fetched adopterId: $adopterId');

      if (token == null || adopterId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Authentication data not found. Please log in again.';
        });
        return;
      }

      setState(() {
        _authToken = token;
        _adopterId = adopterId;
      });

      await fetchNotifications();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> fetchNotifications() async {
    if (_authToken == null || _adopterId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Authentication required. Please log in again.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5566/api/adopter/$_adopterId/notifications'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['notifications'] is List) {
          setState(() {
            notifications =
                (data['notifications'] as List).cast<Map<String, dynamic>>();
            isLoading = false;
          });
        } else {
          throw Exception('Invalid notifications data format');
        }
      } else {
        throw _handleApiError(response.statusCode);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().contains('TimeoutException')
            ? 'Request timed out. Please try again.'
            : 'Failed to load notifications: ${e.toString()}';
      });
      debugPrint('Fetch error: $e');
    }
  }

  String _handleApiError(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to view notifications.';
      case 404:
        return 'No notifications found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Failed to load notifications (Error $statusCode)';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String formatFriendlyDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('h:mm a').format(dateTime)}';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE at h:mm a').format(dateTime);
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  Widget buildNotificationCard(Map<String, dynamic> notif) {
    final status = notif['status'] ?? '';
    final dateLabel = formatFriendlyDate(notif['created_at'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.notifications_active,
            color: getStatusColor(status), size: 28),
        title: Text(
          notif['title'] ?? '',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notif['message'] ?? '',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dateLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
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
        title: const Text("Notifications"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : notifications.isEmpty
                  ? const Center(child: Text("No notifications found."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return buildNotificationCard(notifications[index]);
                      },
                    ),
    );
  }
}
