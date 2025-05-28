import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_home_screen.dart';
import 'adopted_pet_list_screen.dart';
import 'user_bottom_nav_bar.dart';

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
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAuthAndFetch();
  }

  Future<void> _initializeAuthAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final adopterId = prefs.getInt('adopter_id');

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
      await updateUnreadCount();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> deleteAllNotifications() async {
    if (_authToken == null || _adopterId == null) return;

    final url = Uri.parse(
        'http://127.0.0.1:5566/api/adopter/$_adopterId/notifications/remove_all');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchNotifications();
        await updateUnreadCount();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications deleted.')),
        );
      } else {
        debugPrint(
            'Failed to delete all notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
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
      notifications = [];
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
        throw Exception(_handleApiError(response.statusCode));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().contains('TimeoutException')
            ? 'Request timed out. Please try again.'
            : 'Failed to load notifications: ${e.toString()}';
      });
    }
  }

  Future<void> fetchAndMarkNotificationAsRead(int notificationId) async {
    if (_authToken == null) return;

    final url = Uri.parse(
        'http://127.0.0.1:5566/api/adopter/notifications/$notificationId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications.map((n) {
            if (n['id'] == notificationId) {
              return {...n, 'is_read': true};
            }
            return n;
          }).toList();
        });
        await updateUnreadCount();
      } else {
        debugPrint('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markNotificationAsRead(int notificationId, bool markRead) async {
    if (_authToken == null) return;

    final url = Uri.parse(
        'http://127.0.0.1:5566/api/adopter/notifications/$notificationId/read-status');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_read': markRead}),
      );

      if (response.statusCode == 200) {
        await fetchNotifications();
        await updateUnreadCount();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              markRead
                  ? 'Notification marked as read.'
                  : 'Notification marked as unread.',
            ),
            backgroundColor: markRead ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        debugPrint(
            'Failed to mark as ${markRead ? 'read' : 'unread'}: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error marking as ${markRead ? 'read' : 'unread'}: $e');
    }
  }

  Future<void> updateUnreadCount() async {
    if (_authToken == null || _adopterId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5566/api/adopter/$_adopterId/notifications/unread_count'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          unreadCount = data['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Unread count error: $e');
    }
  }

  void onNotificationTap(Map<String, dynamic> notification) async {
    final isRead = notification['is_read'] ?? false;
    final notificationId = notification['id'];

    // Automatically mark as read if not already
    if (!isRead) {
      await fetchAndMarkNotificationAsRead(notificationId);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Options'),
        content: Text(
          isRead
              ? 'Would you like to mark this notification as unread or view all your adopted pets?'
              : 'Would you like to view all your adopted pets?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (isRead)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await markNotificationAsRead(notificationId, false);
              },
              child: const Text('Mark as Unread'),
            ),
          TextButton(
            onPressed: _adopterId != null
                ? () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdoptedPetListScreen(
                          adopterId: _adopterId!,
                          applicationId: 0,
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  String _handleApiError(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'Permission denied.';
      case 404:
        return 'No notifications found.';
      case 500:
        return 'Server error. Try again later.';
      default:
        return 'Error $statusCode occurred.';
    }
  }

  // Color mapping based on status and category (manual mapping for *_reject)
  Color getNotificationColor(String status, String category) {
    status = status.toLowerCase();
    category = category.toLowerCase();

    // Any rejected status: red (covers application_reject, interview_reject, approved_reject)
    if (status == 'rejected') {
      return Colors.red;
    }

    // Approved: green
    if (status == 'approved' && category == 'approved') {
      return Colors.green;
    }

    // Completed: green
    if (status == 'completed' && category == 'completed') {
      return Colors.green;
    }

    // In progress (pending, in queue): orange
    if (status == 'pending' || status == 'in queue') {
      return Colors.orange;
    }

    // Interview scheduled (application): green
    if (status == 'interview' && category == 'application') {
      return Colors.green;
    }

    // Interview scheduled (interview): orange
    if (status == 'interview' && category == 'interview') {
      return Colors.orange;
    }

    // Default
    return Colors.orange;
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
    } catch (_) {
      return 'Unknown date';
    }
  }

  Widget buildNotificationCard(Map<String, dynamic> notif) {
    final status = notif['status'] ?? '';
    final category = notif['category'] ?? '';
    final dateLabel = formatFriendlyDate(notif['created_at'] ?? '');
    final isRead = notif['is_read'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: isRead ? Colors.white : Colors.blue.shade50, // Highlight unread
      child: ListTile(
        onTap: () => onNotificationTap(notif),
        leading: Stack(
          children: [
            Icon(Icons.notifications_active,
                color: getNotificationColor(status, category), size: 28),
            if (!isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notif['title'] ?? '',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isRead ? Colors.black : Colors.blue.shade900,
          ),
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
                    color: getNotificationColor(status, category)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: getNotificationColor(status, category),
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
        trailing: isRead
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : const Icon(Icons.mark_email_unread,
                color: Colors.orange, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete All Notifications',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete All Notifications'),
                  content: const Text(
                      'Are you sure you want to delete all notifications? This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete All',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await deleteAllNotifications();
              }
            },
          ),
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : notifications.isEmpty
                  ? const Center(child: Text('No notifications found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return buildNotificationCard(notifications[index]);
                      },
                    ),
      bottomNavigationBar: UserBottomNavBar(
        adopterId: _adopterId ?? 0,
        currentIndex:
            0, // Set to 0, 1, or 2 depending on which tab you want highlighted
        applicationId: 0,
      ),
    );
  }
}
