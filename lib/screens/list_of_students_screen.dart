import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListOfStudentsScreen extends StatefulWidget {
  final String teacherClass;
  const ListOfStudentsScreen({super.key, required this.teacherClass});

  @override
  State<ListOfStudentsScreen> createState() => _ListOfStudentsScreenState();
}

class _ListOfStudentsScreenState extends State<ListOfStudentsScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Class ${widget.teacherClass} Students"),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search student by name...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Student List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Student') // Filter students only
                  /*.where('class',
                      isEqualTo:
                          widget.teacherClass.toString())*/ // Filter by class
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No students found in this class."));
                }

                var students = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['name']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student =
                        students[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child:
                              Text((student['name'] ?? 'U')[0].toUpperCase()),
                        ),
                        title: Text(student['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            Text("Roll No: ${student['rollNo'] ?? 'N/A'}"),
                        trailing:
                            const Icon(Icons.info_outline, color: Colors.blue),
                        onTap: () {
                          // Yahan aap Student Detail screen par navigate kar sakti hain
                        },
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
