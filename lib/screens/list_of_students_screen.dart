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

  // ---- School ERP color palette (matches app theme) ----
  static const Color navy = Color(0xFF1E3A5F);
  static const Color navyDark = Color(0xFF16304E);
  static const Color accentBlue = Color(0xFF2E86AB);
  static const Color lightGrey = Color(0xFFF4F6F9);

  // ---- Responsive helper: gives breathing room on wide screens without
  // squeezing content into a narrow centered column ----
  double _horizontalPadding(double width) {
    if (width >= 1200) return 24;
    if (width >= 900) return 20;
    if (width >= 600) return 16;
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double hPad = _horizontalPadding(width);

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search student by name...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, color: navy),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // Student List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'Student')
                        .where('class', isEqualTo: widget.teacherClass)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Surface the real Firestore error instead of a silent
                      // blank screen (permission-denied / missing-index /
                      // type-mismatch errors all land here).
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Error loading students:\n${snapshot.error}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: navy),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState(
                          "No students found in this class.",
                        );
                      }

                      final int totalStudents = snapshot.data!.docs.length;

                      var students = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        final name = data['name'];
                        return name != null &&
                            name.toString().toLowerCase().contains(searchQuery);
                      }).toList();

                      return Column(
                        children: [
                          _buildTotalCountBar(hPad, totalStudents),
                          Expanded(
                            child: students.isEmpty
                                ? _buildEmptyState(
                                    "No students match your search.",
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.fromLTRB(
                                      hPad,
                                      4,
                                      hPad,
                                      24,
                                    ),
                                    itemCount: students.length,
                                    itemBuilder: (context, index) {
                                      var student =
                                          students[index].data()
                                              as Map<String, dynamic>;
                                      return _buildStudentCard(student);
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotalCountBar(double hPad, int totalStudents) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Total Students: $totalStudents",
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Class ${widget.teacherClass} Students",
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [navy, navyDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white.withOpacity(0.08)),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: navy.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 42,
                color: navy,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final String name = student['name'] ?? 'Unnamed Student';
    final String rollNo = (student['rollNo'] ?? 'N/A').toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: navy.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        leading: CircleAvatar(
          radius: 24,
          backgroundColor: navy.withOpacity(.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "S",
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),

        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: navy,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 5),
              Text(
                "Roll No: $rollNo",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
