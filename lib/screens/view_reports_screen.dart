import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_connect/screens/report_details_screen.dart';

class StudentReportViewScreen extends StatelessWidget {
  const StudentReportViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Current logged-in student ki ID
    final String currentStudentId =
        FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Monthly Reports",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1746A2),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('monthly_reports')
            .where('studentId', isEqualTo: currentStudentId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var report = reports[index].data() as Map<String, dynamic>;
              return _buildReportCard(context, report);
            },
          );
        },
      ),
    );
  }

  // Report Card Design
  Widget _buildReportCard(BuildContext context, Map<String, dynamic> data) {
    String performance = data['overallPerformance'] ?? "N/A";
    Color perfColor = performance == "Excellent"
        ? Colors.green
        : (performance == "Good" ? Colors.blue : Colors.orange);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: perfColor.withValues(alpha: 0.1),
          child: Icon(Icons.description, color: perfColor),
        ),
        title: Text(data['month'] ?? "Month Unknown",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Performance: $performance"),
            Text("Class: ${data['class']}"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(reportData: data),
            ),
          );
        },
      ),
    );
  }

  // Empty State Design
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text("No reports found yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
