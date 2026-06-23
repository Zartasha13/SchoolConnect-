import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmitComplaintPage extends StatefulWidget {
  const SubmitComplaintPage({super.key});

  @override
  State<SubmitComplaintPage> createState() => _SubmitComplaintPageState();
}

class _SubmitComplaintPageState extends State<SubmitComplaintPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  String? _selectedCategory;
  String _selectedPriority = "Medium";
  bool _isLoading = true;
  String _name = "Loading...";
  String _rollNo = "N/A";
  String _class = "N/A";

  bool _titleError = false;
  bool _detailError = false;
  bool _categoryError = false;

  final List<String> _categories = [
    "Infrastructure",
    "Staff Issue",
    "Attendance",
    "Others"
  ];

  Future<void> _submitComplaint() async {
    setState(() {
      _titleError = _titleController.text.isEmpty;
      _detailError = _detailController.text.isEmpty;
      _categoryError = _selectedCategory == null;
    });

    if (_categoryError || _titleError || _detailError) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('complaints').add({
        "userId": user?.uid,
        "studentName": _name,
        "rollNo": _rollNo,
        "class": _class,
        "category": _selectedCategory,
        "title": _titleController.text,
        "details": _detailController.text,
        "priority": _selectedPriority,
        "status": "Pending",
        "sendTo": "Admin",
        "createdAt": FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _titleController.clear();
        _detailController.clear();
        setState(() => _selectedCategory = null);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Complaint Submitted Successfully!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _name = data['name'] ?? "No Name";
            _rollNo = data['rollNo'] ?? "N/A";
            _class = data['class'] ?? "N/A";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("Submit Complaints",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue[800]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        labelText: "Complaint Category *",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.apps),
                        errorText: _categoryError ? "Select a category" : null),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() {
                      _selectedCategory = val;
                      _categoryError = false;
                    }),
                  ),
                  const SizedBox(height: 15),

                  // Title
                  TextField(
                      controller: _titleController,
                      onChanged: (val) => setState(() => _titleError = false),
                      decoration: InputDecoration(
                          labelText: "Complaint Title *",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.edit),
                          errorText: _titleError ? "Title is required" : null)),
                  const SizedBox(height: 15),

                  // Details
                  TextField(
                      controller: _detailController,
                      onChanged: (val) => setState(() => _detailError = false),
                      maxLines: 4,
                      decoration: InputDecoration(
                          labelText: "Complaint Details *",
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                          errorText:
                              _detailError ? "Details are required" : null)),
                  const SizedBox(height: 20),

                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Priority Level",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["High", "Medium", "Low"]
                        .map((level) => ChoiceChip(
                              label: Text(level),
                              selected: _selectedPriority == level,
                              onSelected: (selected) =>
                                  setState(() => _selectedPriority = level),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800]),
                      child: const Text("Submit Complaint",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const Divider(height: 50, thickness: 2),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("My Submitted Complaints",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  _buildMyComplaintsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildMyComplaintsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('userId',
              isEqualTo: FirebaseAuth
                  .instance.currentUser?.uid) // Sirf us user ki complaints
          .orderBy('createdAt', descending: true) // Nayi complaint sab se upar
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var complaints = snapshot.data!.docs;

        if (complaints.isEmpty) {
          return const Center(child: Text("No complaints submitted yet."));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            var data = complaints[index].data() as Map<String, dynamic>;

            // Status ka color manage karne ke liye
            Color statusColor = Colors.orange; // Pending
            if (data['status'] == 'Accepted') {
              statusColor = Colors.green;
            } else if (data['status'] == 'Rejected') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: ListTile(
                title: Text(data['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Category: ${data['category']}"),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(data['status'],
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold)),
                ),
                onTap: () {
                  _showComplaintDetails(
                      data); // <--- Bas yahan ye function call karna hai
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showComplaintDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complaint Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Category:", data['category']),
            _detailRow("Title:", data['title']),
            _detailRow("Details:", data['details']),
            _detailRow("Submitted By:", _name),
            _detailRow("Submitted To:", data['sendTo'] ?? "Admin"),
            _detailRow("Status:", data['status']),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        Expanded(child: Text(value)),
      ]),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Roll No: $_rollNo | Class: $_class"),
            ]),
          ],
        ),
      ),
    );
  }
}
