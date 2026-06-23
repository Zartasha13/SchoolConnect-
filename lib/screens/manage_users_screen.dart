import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:school_connect/screens/class_wise_students_screen.dart';
import 'add_users_screen.dart';

List<List<dynamic>> _parseCsvBackground(String input) => csv.decode(input);

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<String> selectedUserIds = [];
  int selectedTab = 0; // 0 = Students, 1 = Teachers
  List<String> selectedClasses = [];

  void _openAddUserScreen() => Navigator.push(
      context, MaterialPageRoute(builder: (context) => const AddUserScreen()));

  Future<void> _importCSV() async {
    FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result != null && result.files.single.bytes != null) {
      final input = String.fromCharCodes(result.files.single.bytes!);
      List<List<dynamic>> listData = await compute(_parseCsvBackground, input);
      WriteBatch batch = FirebaseFirestore.instance.batch();
      CollectionReference usersRef =
          FirebaseFirestore.instance.collection('users');

      for (var i = 1; i < listData.length; i++) {
        var row = listData[i];
        batch.set(usersRef.doc(), {
          "name": row[0],
          "email": row[1],
          "role": row[2],
          "class": row[3].toString(),
          "createdAt": FieldValue.serverTimestamp()
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bulk imported successfully!")));
      }
    }
  }

// 1. Delete function updated with confirmation logic (logic in button)
  void _removeSelected() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var id in selectedUserIds) {
      batch.delete(FirebaseFirestore.instance.collection('users').doc(id));
    }
    await batch.commit();
    setState(() => selectedUserIds.clear());
  }

  Future<void> _promoteSelectedClasses() async {
    if (selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one class")),
      );
      return;
    }
    if (selectedClasses.contains('10')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Class 10 cannot be promoted.")),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Promote Classes"),
        content: Text(selectedClasses
            .map((e) => "Class $e → Class ${int.parse(e) + 1}")
            .join("\n")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Promote")),
        ],
      ),
    );

    if (confirm != true) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (String classNo in selectedClasses) {
      QuerySnapshot students = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('class', isEqualTo: classNo)
          .get();
      for (var student in students.docs) {
        batch.update(
            student.reference, {'class': (int.parse(classNo) + 1).toString()});
      }
    }
    await batch.commit();
    setState(() => selectedClasses.clear());
  }

  void _showEditClassDialog(QueryDocumentSnapshot user) {
    TextEditingController classController =
        TextEditingController(text: (user.data() as Map)['class'] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Assign New Class"),
        content: TextField(
          controller: classController,
          decoration: const InputDecoration(labelText: "New Class Number"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          FilledButton(
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Confirm Update"),
                  content: Text("Change class to ${classController.text}?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("No")),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Yes")),
                  ],
                ),
              );

              if (confirm == true) {
                await user.reference.update({'class': classController.text});
                if (mounted) {
                  Navigator.pop(context); // Dialog band
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Class updated successfully!")));
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
          title: const Text("Manage Users"), backgroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          var students = docs
              .where((u) => (u.data() as Map)['role'] == 'Student')
              .toList();
          var teachers = docs
              .where((u) => (u.data() as Map)['role'] == 'Teacher')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStats(docs),
                const SizedBox(height: 20),
                Row(children: [
                  FilledButton.icon(
                      onPressed: _openAddUserScreen,
                      icon: const Icon(Icons.add),
                      label: const Text("Create a User")),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                      onPressed: _importCSV,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Import CSV")),
                  const Spacer(),
                ]),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    _tabButton("Students", 0),
                    _tabButton("Teachers", 1)
                  ]),
                ),
                const SizedBox(height: 15),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        if (selectedTab == 0) ..._buildStudentList(),
                        if (selectedTab == 1) ..._buildTeacherList(teachers),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 1. Promote Button (Sirf Students ke liye)
                            if (selectedTab == 0)
                              ElevatedButton.icon(
                                  onPressed: _promoteSelectedClasses,
                                  icon: const Icon(Icons.arrow_upward),
                                  label: const Text("Promote Selected"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white)),

                            // 2. Assign New Class Button (Sirf Teachers ke liye)
                            if (selectedTab == 1)
                              ElevatedButton.icon(
                                onPressed: selectedUserIds.isEmpty
                                    ? null
                                    : () {
                                        // Yahan wo logic call hogi agar aap single teacher select karein
                                        if (selectedUserIds.length == 1) {
                                          var teacher = teachers.firstWhere(
                                              (t) =>
                                                  t.id ==
                                                  selectedUserIds.first);
                                          _showEditClassDialog(teacher);
                                        }
                                      },
                                icon: const Icon(Icons.school),
                                label: const Text("Assign New Class"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white),
                              ),

                            const SizedBox(width: 10),

                            // 3. Delete/Remove Button (Dono tabs ke liye)
                            ElevatedButton.icon(
                              onPressed: (selectedTab == 0 &&
                                          selectedClasses.isEmpty) ||
                                      (selectedTab == 1 &&
                                          selectedUserIds.isEmpty)
                                  ? null
                                  : () async {
                                      bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Confirm Action"),
                                          content: Text(selectedTab == 0
                                              ? "Are you sure you want to delete selected classes?"
                                              : "Are you sure you want to remove ${selectedUserIds.length} teacher(s)?"),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text("Cancel")),
                                            FilledButton(
                                                style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text("Confirm")),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        if (selectedTab == 0) {
                                          // Delete Class Logic
                                          setState(
                                              () => selectedClasses.clear());
                                        } else {
                                          // Remove Teacher Logic
                                          _removeSelected();
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.delete),
                              label: Text(selectedTab == 0
                                  ? "Delete Selected Class"
                                  : "Remove Selected Teachers"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: selectedTab == index
                          ? const Color(0xFF1746A2)
                          : Colors.transparent,
                      width: 3))),
          child: Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selectedTab == index
                      ? const Color(0xFF1746A2)
                      : Colors.grey)),
        ),
      ),
    );
  }

  List<Widget> _buildStudentList() {
    return List.generate(10, (index) {
      String classNo = (index + 1).toString();

      // CheckboxListTile ke bajaye ListTile use karna zyadah stable hai
      return ListTile(
        leading: Checkbox(
          value: selectedClasses.contains(classNo),
          onChanged: (value) => setState(() => value == true
              ? selectedClasses.add(classNo)
              : selectedClasses.remove(classNo)),
        ),
        title: Text("Class $classNo"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Yahan navigation handle ho raha hai
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassStudentsScreen(classNumber: classNo),
            ),
          );
        },
      );
    });
  }

  List<Widget> _buildTeacherList(List<QueryDocumentSnapshot> teachers) =>
      teachers.map((t) => _userTile(t)).toList();

  Widget _userTile(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>? ?? {};
    return CheckboxListTile(
      value: selectedUserIds.contains(user.id),
      title: Text(data['name'] ?? "No Name"),
      subtitle:
          Text("${data['email'] ?? ""} | Class: ${data['class'] ?? "N/A"}"),
      onChanged: (bool? v) {
        setState(() {
          if (v == true) {
            selectedUserIds.add(user.id);
          } else {
            selectedUserIds.remove(user.id);
          }
        });
      },
    );
  }

  Widget _buildStats(List<QueryDocumentSnapshot> docs) {
    int students =
        docs.where((u) => (u.data() as Map)['role'] == 'Student').length;
    int teachers =
        docs.where((u) => (u.data() as Map)['role'] == 'Teacher').length;
    return Row(children: [
      _statCard("Students", students.toString(), Icons.person),
      const SizedBox(width: 16),
      _statCard("Teachers", teachers.toString(), Icons.school),
      const SizedBox(width: 16),
      _statCard("Total", docs.length.toString(), Icons.group),
    ]);
  }

  Widget _statCard(String title, String value, IconData icon) => Expanded(
      child: Card(
          child: ListTile(
              title: Text(title),
              subtitle: Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              trailing: Icon(icon, color: const Color(0xFF1746A2)))));
}
