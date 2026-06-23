import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassStudentsScreen extends StatefulWidget {
  final String classNumber;

  const ClassStudentsScreen({
    super.key,
    required this.classNumber,
  });

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  List<String> selectedStudents = [];

  Future<void> deleteSelectedStudents() async {
    if (selectedStudents.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Students"),
        content: Text(
          "Are you sure you want to delete ${selectedStudents.length} selected student(s)?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (String id in selectedStudents) {
      batch.delete(
        FirebaseFirestore.instance.collection('users').doc(id),
      );
    }

    await batch.commit();

    setState(() {
      selectedStudents.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selected students deleted successfully"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Class ${widget.classNumber} Students"),
        backgroundColor: const Color(0xFF1746A2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  "Class ${widget.classNumber}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed:
                      selectedStudents.isEmpty ? null : deleteSelectedStudents,
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete Selected"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Student')
                  .where('class', isEqualTo: widget.classNumber)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No students found in this class"),
                  );
                }

                final students = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final data = student.data() as Map<String, dynamic>;

                    final name = data['name'] ?? '';
                    final email = data['email'] ?? '';
                    final role = data['role'] ?? '';
                    final studentClass = data['class'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: CheckboxListTile(
                        value: selectedStudents.contains(student.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedStudents.add(student.id);
                            } else {
                              selectedStudents.remove(student.id);
                            }
                          });
                        },
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: $email"),
                            Text("Class: $studentClass"),
                            Text("Role: $role"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
