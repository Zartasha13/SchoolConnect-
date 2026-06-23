import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SendLeaveRequestPage extends StatefulWidget {
  const SendLeaveRequestPage({super.key});

  @override
  State<SendLeaveRequestPage> createState() => _SendLeaveRequestPageState();
}

class _SendLeaveRequestPageState extends State<SendLeaveRequestPage> {
  final TextEditingController _reasonController = TextEditingController();
  String? _studentName, _rollNo, _studentClass;
  DateTime? _fromDate, _toDate;
  String? _selectedType;
  bool _isLoading = true;

  final List<String> _types = ["Sick Leave", "Casual Leave", "Emergency"];

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _studentName = data['name'];
          _rollNo = data['rollNo'];
          _studentClass = data['class'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_fromDate == null ||
        _toDate == null ||
        _selectedType == null ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('leave_requests').add({
        "studentName": _studentName,
        "rollNo": _rollNo,
        "class": _studentClass,
        "leaveType": _selectedType,
        "fromDate": Timestamp.fromDate(_fromDate!),
        "toDate": Timestamp.fromDate(_toDate!),
        "reason": _reasonController.text.trim(),
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
        'studentId': FirebaseAuth.instance.currentUser!.uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Request Submitted!"),
            backgroundColor: Colors.green));
        _reasonController.clear();
        setState(() {
          _fromDate = null;
          _toDate = null;
          _selectedType = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLeaveDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Details",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Name:", data['studentName']),
            _detailRow("Type:", data['leaveType']),
            _detailRow(
                "From:",
                DateFormat('dd-MM-yyyy')
                    .format((data['fromDate'] as Timestamp).toDate())),
            _detailRow(
                "To:",
                DateFormat('dd-MM-yyyy')
                    .format((data['toDate'] as Timestamp).toDate())),
            const SizedBox(height: 10),
            const Text("Reason:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['reason']),
          ],
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("Send Leave Request",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue[800]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                              labelText: "Leave Type",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.work_outline)),
                          items: _types
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedType = val),
                          initialValue: _selectedType,
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child:
                                  _buildDateTile("From Date", _fromDate, true)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildDateTile("To Date", _toDate, false)),
                        ]),
                        const SizedBox(height: 10),
                        TextField(
                            controller: _reasonController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: "Reason",
                                border: OutlineInputBorder())),
                        const SizedBox(height: 15),
                        SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                                onPressed: _submitRequest,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800]),
                                child: const Text("Submit Request",
                                    style: TextStyle(color: Colors.white)))),
                      ],
                    ),
                  ),
                ),
                // History Section
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: const [
                            Icon(Icons.history, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Leave History",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('leave_requests')
                              .where('studentId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser!.uid)
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            var docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return const Center(
                                  child: Text("No history yet"));
                            }
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                var data =
                                    docs[index].data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  child: ListTile(
                                    onTap: () => _showLeaveDetails(data),
                                    title: Text(data['reason'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Text(
                                        "Date: ${DateFormat('dd-MM-yyyy').format((data['fromDate'] as Timestamp).toDate())}"),
                                    trailing: _buildStatusBadge(data['status']),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const CircleAvatar(radius: 25, child: Icon(Icons.person)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_studentName ?? "Loading...",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Roll No: ${_rollNo ?? 'N/A'}"),
          ]),
          const Spacer(),
          Chip(
              label: Text(_studentClass ?? "N/A",
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.blue[900]),
        ]),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Accepted'
        ? Colors.green
        : (status == 'Rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, bool isFrom) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2027));
        if (picked != null) {
          setState(() => isFrom ? _fromDate = picked : _toDate = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today)),
        child: Text(
            date == null ? "Select" : DateFormat('dd-MM-yyyy').format(date)),
      ),
    );
  }
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 5),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
