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
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        title: const Text(
          "My Monthly Reports",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
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
        : performance == "Good"
        ? Colors.blue
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: perfColor.withOpacity(.12),
          child: Icon(Icons.assignment_rounded, color: perfColor),
        ),

        title: Text(
          data['month'] ?? "Unknown Month",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const Icon(Icons.school, size: 15, color: Colors.grey),
              const SizedBox(width: 5),

              Text(
                "Class: ${data['class']}",
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: perfColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  performance,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: perfColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        trailing: const Icon(Icons.info_outline, color: Color(0xFF2E86AB)),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(reportData: data),
            ),
          );
        },
      ),
    );
  } // Empty State Design

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text(
            "No reports found yet.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
