import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_connect/screens/complaints_details_screen.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  String filter = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Complaints",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff1746A2),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("complaints")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          int total = docs.length;
          int pending = docs.where((d) => d['status'] == "Pending").length;
          int resolved = docs.where((d) => d['status'] == "Resolved").length;

          // Filtering logic
          final filteredDocs = docs.where((d) {
            if (filter == "All") return true;
            return d['status'] == filter;
          }).toList();

          return Column(
            children: [
              // Stats Cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _statCard("Total", total.toString(), Colors.blue),
                    _statCard("Pending", pending.toString(), Colors.orange),
                    _statCard("Resolved", resolved.toString(), Colors.green),
                  ],
                ),
              ),
              // Filter Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ["All", "Pending", "In Progress", "Resolved"]
                    .map((f) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                              label: Text(f),
                              selected: filter == f,
                              onSelected: (_) => setState(() => filter = f)),
                        ))
                    .toList(),
              ),
              // List View
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(data['title'] ?? "No Title",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        // Subtitle se status hata diya gaya hai
                        subtitle: Text(DateFormat('dd MMM yyyy')
                            .format((data['createdAt'] as Timestamp).toDate())),
                        trailing:
                            _buildStatusBadge(data['status'] ?? "Pending"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ComplaintDetailsPage(
                                    docId: filteredDocs[index].id))),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Resolved'
        ? Colors.green
        : (status == 'In Progress' ? Colors.blue : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _statCard(String title, String count, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(children: [
            Text(title,
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Text(count,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color))
          ]),
        ),
      ),
    );
  }
}
