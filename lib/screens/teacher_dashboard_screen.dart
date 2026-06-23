import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_connect/screens/attendance_screen.dart';
import 'package:school_connect/screens/monthly_reports_screen.dart';
import 'package:school_connect/screens/view_announcements_screen.dart';
import 'package:school_connect/screens/welcome_screen.dart';
import 'package:school_connect/screens/teacher_profile_screen.dart';
import 'package:school_connect/screens/list_of_students_screen.dart';
import 'package:school_connect/screens/manage_leave_screen.dart';
import 'package:school_connect/screens/post_homework_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = "Loading...";
  String userClass = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              userName = data['name'] ?? "Teacher";
              userClass = data.containsKey('class')
                  ? data['class'].toString()
                  : "No Class Assigned";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class: $userClass',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount:
                          isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                      children: [
                        _buildDashboardCard(
                          icon: Icons.check_circle_outline,
                          title: 'Attendance',
                          description:
                              'Mark daily attendance for class $userClass.',
                          buttonText: 'Mark Attendance',
                          onPressed: () {
                            print(
                                "Button clicked!"); // Check karein console mein ye message aa raha hai?
                            // Check karein ke class data loaded hai ya nahi
                            if (userClass == "Loading..." ||
                                userClass == "No Class Assigned") {
                              print(
                                  "Class is not loaded yet"); // Check karein agar ye print ho raha hai
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Class data not ready yet!")),
                              );
                            } else {
                              print("Navigating to Attendance...");
                              // Yahan navigator push lagayein
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MarkAttendanceScreen(
                                    teacherClass:
                                        userClass, // Dashboard wali class pass ho rahi hai
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons
                              .calendar_month_outlined, // Leave request ke liye suit karta hai
                          title: 'Manage Leaves',
                          description:
                              'View, accept or reject student leave requests.',
                          buttonText: 'View Requests',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ManageLeavePage()),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.campaign_outlined,
                          title: 'Announcements',
                          description: 'Create and view class/school notices.',
                          buttonText: 'View',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ViewAnnouncementsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.assignment_outlined,
                          title: 'Post Homework',
                          description: 'Post new daily assignments.',
                          buttonText: 'Post Homework',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PostHomeworkScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.assessment_outlined,
                          title: 'Monthly Reports',
                          description:
                              'View and update individual student progress.',
                          buttonText: 'Upload Reports',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MonthlyReportsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.group_outlined,
                          title: 'My Students',
                          description: 'View all students in the class.',
                          buttonText: 'View Class',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListOfStudentsScreen(
                                    teacherClass:
                                        userClass), // userClass wahi variable hai jo aapne dashboard mein fetch kiya tha
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 26),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 12),
              const Text(
                'TEACHER DASHBOARD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Welcome, $userName',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                radius: 16,
                child: const Text('🎓', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1D4ED8)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF1D4ED8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SchoolConnect',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            Icons.grid_view_rounded,
            'Dashboard',
            isSelected: true,
          ),
          _buildDrawerItem(
            Icons.person_outline_rounded,
            'Profile',
          ), // Profile button
          const Spacer(),
          _buildDrawerItem(
            Icons.logout_rounded,
            'Logout',
            isLogout: true,
          ), // Logout button
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title, {
    bool isSelected = false,
    bool isLogout = false,
  }) {
    return ListTile(
      selected: isSelected,
      leading: Icon(
        icon,
        color: isLogout
            ? Colors.red
            : (isSelected ? const Color(0xFF1D4ED8) : Colors.grey),
      ),
      title: Text(
        title,
        style: TextStyle(color: isLogout ? Colors.red : Colors.black),
      ),
      onTap: () {
        Navigator.pop(context);
        if (title == 'Logout') {
          _showLogoutDialog(context);
        } else if (title == 'Profile') {
          // Yahan maine sahi class name use kiya hai
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      },
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          // Halka sa shadow dene se Admin dashboard jaisa feel aayega
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 35, color: const Color(0xFF1D4ED8)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),

          // --- YE WALI LINE ZAROORI HAI ---
          const Spacer(),
          // --------------------------------

          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
