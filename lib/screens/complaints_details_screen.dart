import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final String docId;
  const ComplaintDetailsPage({super.key, required this.docId});

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  // Status update function - Firestore mein update karega
  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection("complaints")
          .doc(widget.docId)
          .update({"status": newStatus});

      // Success SnackBar (Green)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status successfully updated to $newStatus"),
          backgroundColor: Colors.green, // Yahan green color diya
          behavior: SnackBarBehavior
              .floating, // Is se bar thoda utha hua (floating) dikhega
        ),
      );
    } catch (e) {
      // Error SnackBar (Red)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error updating status"),
          backgroundColor: Colors.red, // Yahan red color diya
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Complaint Details"),
        backgroundColor: const Color(0xff1746A2),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("complaints")
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Complaint not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Date Formatting
          String dateStr = "N/A";
          if (data['createdAt'] != null) {
            dateStr = DateFormat('dd MMM yyyy, hh:mm a')
                .format((data['createdAt'] as Timestamp).toDate());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow(
                            "Submitted By:", data['studentName'] ?? "N/A"),
                        _buildRow("Class:", data['class'] ?? "N/A"),
                        _buildRow("Roll No:", data['rollNo'] ?? "N/A"),
                        const Divider(),
                        _buildRow("Title", data['title'] ?? "No Title"),
                        _buildRow("Date", dateStr),
                        _buildRow(
                            "Category", data['category'] ?? "No Category"),
                        _buildRow("Status", data['status'] ?? "Pending"),
                        const Divider(),
                        const Text("Description:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(data['details'] ?? "No details provided."),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Update Buttons
                const Text("Update Status",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statusButton("In Progress", Colors.blue, data),
                    _statusButton("Resolved", Colors.green, data),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusButton(
      String status, Color baseColor, Map<String, dynamic> data) {
    bool isSelected = data['status'] == status;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            // Agar select hai to solid color, nahi to transparent/light
            backgroundColor:
                isSelected ? baseColor : baseColor.withValues(alpha: 0.05),
            foregroundColor: isSelected ? Colors.white : baseColor,
            elevation: isSelected ? 3 : 0,
            shadowColor: baseColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              // Border dikhegi taake professional look aaye
              side: BorderSide(
                color: baseColor,
                width: isSelected ? 0 : 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            // Sirf tab update ho agar status change ho raha ho
            if (!isSelected) {
              _updateStatus(status);
            }
          },
          child: Text(
            status,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
