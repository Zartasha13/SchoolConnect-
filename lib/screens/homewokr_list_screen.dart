import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeacherHomeworkListScreen extends StatelessWidget {
  const TeacherHomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? teacherId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Posted Homework"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('homework')
            .where('teacherId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid.trim())
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No homework posted yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              String assignedDate = data['assignedDate'] != null
                  ? DateFormat('dd MMM yyyy')
                      .format((data['assignedDate'] as Timestamp).toDate())
                  : "N/A";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  onTap: () {
                    // Yahan modal bottom sheet open hoga
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, // Taake pura content dikh sake
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // Jitna content hai utna hi size
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                  child: Container(
                                      width: 40,
                                      height: 4,
                                      color: Colors.grey[300])),
                              const SizedBox(height: 20),
                              Text(data['title'] ?? "No Title",
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const Divider(),
                              const SizedBox(height: 10),
                              Text("Subject: ${data['subject']}",
                                  style: const TextStyle(fontSize: 16)),
                              Text("Class: ${data['class']}",
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 15),
                              const Text("Description:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(data['description'] ?? "No description."),
                              const SizedBox(height: 15),
                              Text(
                                  "Assigned Date: ${data['assignedDate'] != null ? DateFormat('dd MMM yyyy').format((data['assignedDate'] as Timestamp).toDate()) : "N/A"}"),
                              Text(
                                  "Due Date: ${data['dueDate'] != null ? DateFormat('dd MMM yyyy').format((data['dueDate'] as Timestamp).toDate()) : "N/A"}"),
                              const SizedBox(height: 20),
                              // Attachment ka logic (agar file URL save hai)
                              if (data['fileUrl'] != null)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    /* File open karne ka logic */
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text("View Attachment"),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  title: Text(data['title'] ?? "No Title",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                          "Class: ${data['class']} | Subject: ${data['subject']}"),
                      Text("Assigned: $assignedDate"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Homework"),
        content: const Text("Are you sure you want to delete this homework?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('homework')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
