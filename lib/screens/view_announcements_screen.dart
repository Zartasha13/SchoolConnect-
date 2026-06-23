import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewAnnouncementsScreen extends StatefulWidget {
  const ViewAnnouncementsScreen({super.key});

  @override
  State<ViewAnnouncementsScreen> createState() =>
      _ViewAnnouncementsScreenState();
}

class _ViewAnnouncementsScreenState extends State<ViewAnnouncementsScreen> {
  String userRole = '';
  bool isLoading = true;
  bool isSelectionMode = false;
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          userRole = (userDoc.data() as Map<String, dynamic>)['role']
              .toString()
              .toLowerCase();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteSelectedAnnouncements() async {
    // 1. Pehle Confirmation Dialog dikhayein
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
            "Are you sure you want to delete ${selectedIds.length} announcements?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), // Delete
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    // 2. Agar user ne 'Delete' click kiya (confirm == true), tabhi delete karein
    if (confirm == true) {
      for (String id in selectedIds) {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(id)
            .delete();
      }
      setState(() {
        isSelectionMode = false;
        selectedIds.clear();
      });

      // Optional: Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Selected announcements deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Query announcementsQuery;
    if (userRole == 'student') {
      announcementsQuery = FirebaseFirestore.instance
          .collection('announcements')
          .where('students', isEqualTo: true)
          .orderBy('createdAt', descending: true);
    } else if (userRole == 'teacher') {
      announcementsQuery = FirebaseFirestore.instance
          .collection('announcements')
          .where('teachers', isEqualTo: true)
          .orderBy('createdAt', descending: true);
    } else {
      announcementsQuery = FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1746A2),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Announcements",
          style: TextStyle(
            color: Colors.white, // Yahan heading White ho gayi hai
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Select Button area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSelectionMode)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.select_all),
                    label: const Text("Select"),
                    onPressed: () => setState(() => isSelectionMode = true),
                  ),
                if (isSelectionMode) ...[
                  Text("${selectedIds.length} Selected  "),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: selectedIds.isEmpty
                        ? null
                        : deleteSelectedAnnouncements,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      isSelectionMode = false;
                      selectedIds.clear();
                    }),
                  ),
                ],
              ],
            ),
          ),
          // List area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: announcementsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No announcements available"));
                }

                final announcements = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final doc = announcements[index];
                    final String id = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isSelected = selectedIds.contains(id);
                    Timestamp? timestamp = data['createdAt'] as Timestamp?;
                    DateTime date = timestamp?.toDate() ?? DateTime.now();

                    return Card(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedIds.add(id);
                                    } else {
                                      selectedIds.remove(id);
                                    }
                                  });
                                },
                              )
                            : const Icon(Icons.campaign,
                                color: Color(0xFF1746A2)),
                        title: Text(data['title'] ?? 'No Title',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? '',
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(
                                "Posted on: ${date.day}/${date.month}/${date.year}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        onTap: () {
                          if (isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                selectedIds.remove(id);
                              } else {
                                selectedIds.add(id);
                              }
                            });
                          } else {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(data['title'] ?? 'Title'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (data['imageUrl'] != null &&
                                          data['imageUrl'] != '')
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: Image.network(
                                                data['imageUrl'])),
                                      Text(data['description'] ??
                                          'No description'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
