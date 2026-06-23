import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManageLeavePage extends StatefulWidget {
  const ManageLeavePage({super.key});

  @override
  State<ManageLeavePage> createState() => _ManageLeavePageState();
}

class _ManageLeavePageState extends State<ManageLeavePage> {
  String _selectedFilter = "All";
  String? _teacherClass;

  // Nayi variables selection ke liye
  bool _isSelectionMode = false;
  final List<String> _selectedDocs = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherClass();
  }

  // Delete Function
  Future<void> _confirmDelete() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Requests"),
        content: Text(
            "Are you sure you want to delete ${_selectedDocs.length} requests?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (String id in _selectedDocs) {
        await FirebaseFirestore.instance
            .collection('leave_requests')
            .doc(id)
            .delete();
      }
      setState(() {
        _isSelectionMode = false;
        _selectedDocs.clear();
      });
    }
  }

  Future<void> _fetchTeacherClass() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      setState(() => _teacherClass = doc.data()?['class']);
    }
  }

  Future<void> _showConfirmDialog(String docId, String status) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $status"),
        content: Text("Are you sure you want to $status this request?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    status == "Accepted" ? Colors.green : Colors.red),
            onPressed: () {
              _updateStatus(docId, status);
              Navigator.pop(context);
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_teacherClass == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Leave Requests",
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Delete Button Floating Action Button
      floatingActionButton: (_isSelectionMode && _selectedDocs.isNotEmpty)
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red,
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Delete Selected",
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          _buildSummarySection(),
          if (!_isSelectionMode) _buildFilterTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leave_requests')
                  .where('class', isEqualTo: _teacherClass)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (_selectedFilter != "All") {
                  docs = docs
                      .where((d) => d['status'] == _selectedFilter)
                      .toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("No requests found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildRequestCard(docs[index].id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leave_requests')
          .where('class', isEqualTo: _teacherClass)
          .snapshots(),
      builder: (context, snapshot) {
        int p = 0, a = 0, r = 0;
        if (snapshot.hasData) {
          for (var d in snapshot.data!.docs) {
            if (d['status'] == 'Pending') {
              p++;
            } else if (d['status'] == 'Accepted')
              a++;
            else if (d['status'] == 'Rejected') r++;
          }
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0), // Padding increase ki
              child: Row(children: [
                _summaryCard("Pending", p, Colors.orange),
                const SizedBox(width: 8), // Gap for professional look
                _summaryCard("Accepted", a, Colors.green),
                const SizedBox(width: 8),
                _summaryCard("Rejected", r, Colors.red),
              ]),
            ),
            // Select Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) _selectedDocs.clear();
                  }),
                  icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
                  label: Text(_isSelectionMode ? "Cancel" : "Select"),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
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
            Text("$count",
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
          spacing: 10,
          children: ["All", "Pending", "Accepted", "Rejected"]
              .map((f) => ChoiceChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
                    onSelected: (s) => setState(() => _selectedFilter = f),
                  ))
              .toList()),
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

  Widget _buildRequestCard(String id, Map<String, dynamic> data) {
    bool isSelected = _selectedDocs.contains(id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
      child: ListTile(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              isSelected ? _selectedDocs.remove(id) : _selectedDocs.add(id);
            });
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        LeaveDetailPage(data: data, docId: id)));
          }
        },
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (v) => setState(() =>
                    v! ? _selectedDocs.add(id) : _selectedDocs.remove(id)))
            : CircleAvatar(child: Text(data['studentName'][0].toUpperCase())),
        title: Text("${data['studentName']} (Roll: ${data['rollNo']})",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Reason: ${data['reason']}"),
          Text(
              "Date: ${DateFormat('dd-MM-yyyy').format((data['fromDate'] as Timestamp).toDate())} to ${DateFormat('dd-MM-yyyy').format((data['toDate'] as Timestamp).toDate())}",
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        trailing: (!_isSelectionMode && data['status'] == "Pending")
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                // Accept Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  onPressed: () => _showConfirmDialog(id, "Accepted"),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Accept"),
                ),
                const SizedBox(width: 8),
                // Reject Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () => _showConfirmDialog(id, "Rejected"),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text("Reject"),
                ),
              ])
            : (_isSelectionMode
                ? null
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: data['status'] == 'Accepted'
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(data['status'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: data['status'] == 'Accepted'
                                ? Colors.green
                                : Colors.red)),
                  )),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) =>
      FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(id)
          .update({'status': status});
}

class LeaveDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const LeaveDetailPage({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Leave Details",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue[900],
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow("Student Name:", data['studentName']),
                _detailRow("Roll No:", data['rollNo']),
                _detailRow(
                    "From:",
                    DateFormat('dd-MM-yyyy')
                        .format((data['fromDate'] as Timestamp).toDate())),
                _detailRow(
                    "To:",
                    DateFormat('dd-MM-yyyy')
                        .format((data['toDate'] as Timestamp).toDate())),
                const Divider(),
                const Text("Reason:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Text(data['reason'],
                    style:
                        const TextStyle(fontSize: 15, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 10),
        Text(value, style: const TextStyle(fontSize: 16)),
      ]),
    );
  }
}
