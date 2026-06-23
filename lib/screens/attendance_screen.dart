import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/attendance_history_screen.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String teacherClass;

  const MarkAttendanceScreen({super.key, required this.teacherClass});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  bool isEditing = false;
  bool isLoading = true;
  String todayDate = "";

  @override
  void initState() {
    super.initState();
    todayDate = DateTime.now().toString().split(' ')[0];
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('class', isEqualTo: widget.teacherClass)
        .get();

    setState(() {
      students = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'rollNo': doc['rollNo'],
                'status': 'Not Marked',
              })
          .toList();
      isLoading = false;
    });
  }

  Future<void> saveAttendance() async {
    String date = DateTime.now().toIso8601String().split('T')[0];
    WriteBatch batch = FirebaseFirestore.instance.batch();

    final firestore = FirebaseFirestore.instance;
    for (var student in students) {
      // Nayi flat collection 'attendance_records'
      DocumentReference ref =
          FirebaseFirestore.instance.collection('attendance_records').doc();

      batch.set(ref, {
        "studentId": student['id'],
        "studentName": student['name'],
        "rollNo": student['rollNo'],
        "class": widget.teacherClass,
        "status": student['status'],
        "date": date,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    sendAbsentNotifications(date);
  }

  void sendAbsentNotifications(String date) async {
    for (var student in students) {
      if (student['status'] == 'Absent') {
        await FirebaseFirestore.instance.collection('notifications').add({
          "userId": student['id'],
          // Yahan date ko message mein add kar diya gaya hai
          "message":
              "Attendance Alert: You were marked ABSENT for class '${widget.teacherClass}' on $date. "
                  "If this is a mistake, please contact your class teacher immediately.",
          "type": "attendance",
          "date": Timestamp.now(),
          "createdAt": FieldValue.serverTimestamp(),
          "isRead": false,
        });
      }
    }
  }

  // Attendance Summary calculation
  int get countPresent =>
      students.where((s) => s['status'] == 'Present').length;
  int get countAbsent => students.where((s) => s['status'] == 'Absent').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Attendance",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 1. History Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AttendanceHistoryScreen(), // Yahan apni screen ka class name likhein
                ),
              );
            },
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "Attendance History",
          ),

          // 2. Calendar Button
          IconButton(
            onPressed: () {
              // Calendar ka code
            },
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            tooltip: "Select Date",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryHeader(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Student List",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: () => setState(() => isEditing = !isEditing),
                        icon: Icon(isEditing ? Icons.close : Icons.edit),
                        label: Text(isEditing ? "Cancel" : "Mark Attendance"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var student = students[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(student['rollNo'])),
                          title: Text(student['name']),
                          trailing: isEditing
                              ? _buildEditControls(student)
                              : _buildStatusView(student['status']),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isEditing ? _buildSaveFooter() : null,
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        children: [
          // 1. Date Section
          Column(
            children: [
              const Icon(Icons.calendar_today,
                  color: Color(0xFF0D47A1), size: 22),
              const SizedBox(height: 4),
              Text(
                todayDate, // Yahan aapka date variable aa gaya
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),

          // 2. Vertical Divider
          Container(
            height: 40,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade300,
          ),

          // 3. Summary Section (Class, Present, Absent)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem("Class ${widget.teacherClass}",
                    "${students.length}", Icons.groups, Colors.blue),
                _summaryItem("Present", "$countPresent", Icons.check_circle,
                    Colors.green),
                _summaryItem(
                    "Absent", "$countAbsent", Icons.cancel, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color),
      Text(value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(title)
    ]);
  }

  Widget _buildStatusView(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: status == 'Present'
              ? Colors.green.shade50
              : status == 'Absent'
                  ? Colors.red.shade50
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              color: status == 'Present'
                  ? Colors.green
                  : status == 'Absent'
                      ? Colors.red
                      : Colors.grey)),
    );
  }

  Widget _buildEditControls(Map<String, dynamic> student) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: student['status'] == 'Present'
                ? Colors.green
                : Colors.grey.shade300,
          ),
          onPressed: () {
            setState(() {
              student['status'] = 'Present';
            });
          },
          child: const Text("Present"),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: student['status'] == 'Absent'
                ? Colors.red
                : Colors.grey.shade300,
          ),
          onPressed: () {
            setState(() {
              student['status'] = 'Absent';
            });
          },
          child: const Text("Absent"),
        ),
      ],
    );
  }

  Widget _buildSaveFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm Attendance"),
              content: const Text(
                  "Are you sure you want to save today's attendance?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await saveAttendance();
                    setState(() => isEditing = false);
                  },
                  child: const Text("Yes Save"),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.check),
        label: const Text("SAVE ATTENDANCE"),
      ),
    );
  }
}
