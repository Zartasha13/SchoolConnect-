import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentHomeworkListScreen extends StatefulWidget {
  const StudentHomeworkListScreen({super.key});

  @override
  State<StudentHomeworkListScreen> createState() =>
      _StudentHomeworkListScreenState();
}

class _StudentHomeworkListScreenState extends State<StudentHomeworkListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _viewImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white)),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  void _showHomeworkDetails(BuildContext context, Map<String, dynamic> data) {
    List<dynamic> attachments = data['attachments'] ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['title'] ?? 'Homework Detail'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description Section
              const Text("Description:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(data['description'] ?? "No description provided."),
              const SizedBox(height: 15),

              // Subject Details
              Text("Subject: ${data['subject'] ?? 'N/A'}",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 15),

              // Attachments Section
              if (attachments.isNotEmpty) ...[
                const Text("Attachments:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: attachments.map((url) {
                    bool isPdf = url.toString().toLowerCase().contains(".pdf");

                    return InkWell(
                      onTap: () => _viewImage(context, url),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isPdf ? Icons.picture_as_pdf : Icons.image,
                              color: isPdf ? Colors.red : Colors.blue,
                              size: 40,
                            ),
                            Text(isPdf ? "PDF" : "View",
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Homework Assignments",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1746A2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by subject...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1746A2)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('homework').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No homework available."));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return (data['subject'] ?? "")
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                      child: Text("No homework found for this subject."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildHomeworkCard(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(BuildContext context, Map<String, dynamic> data) {
    Timestamp? dueTimestamp = data['dueDate'] as Timestamp?;
    DateTime dueDate = dueTimestamp?.toDate() ?? DateTime.now();
    bool isUrgent = dueDate.difference(DateTime.now()).inDays <= 2;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.assignment, color: Color(0xFF1746A2)),
        title: Text(data['title'] ?? "No Title",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Subject: ${data['subject'] ?? 'N/A'}"),
            Text("Due: ${DateFormat('dd MMM yyyy').format(dueDate)}",
                style: TextStyle(color: isUrgent ? Colors.red : Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showHomeworkDetails(context, data),
      ),
    );
  }
}
