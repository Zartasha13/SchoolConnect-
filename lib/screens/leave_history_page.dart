import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentHistoryPage extends StatelessWidget {
  const StudentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
          title: const Text("My Leave History"),
          backgroundColor: Colors.blue[900]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leave_requests')
            .where('studentId',
                isEqualTo: user?.uid) // Yahan student ka UID match hoga
            .orderBy('fromDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Koi history nahi mili"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              Color statusColor = data['status'] == 'Accepted'
                  ? Colors.green
                  : (data['status'] == 'Rejected' ? Colors.red : Colors.orange);

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Reason: ${data['reason']}"),
                  subtitle: Text(
                      "Date: ${DateFormat('dd-MM-yyyy').format((data['fromDate'] as Timestamp).toDate())}"),
                  trailing: Chip(
                    label: Text(data['status'],
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: statusColor,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
