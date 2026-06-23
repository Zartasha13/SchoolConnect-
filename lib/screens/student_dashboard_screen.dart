import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/attendance_alerts_screen.dart';
import 'package:school_connect/screens/send_leave_screen.dart';
import 'package:school_connect/screens/submit_complaints_screen.dart';
import 'package:school_connect/screens/view_announcements_screen.dart';
import 'package:school_connect/screens/view_homework_screen.dart';
import 'package:school_connect/screens/view_reports_screen.dart';
import 'package:school_connect/screens/welcome_screen.dart';
import 'package:school_connect/screens/student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Dynamic variables
  String userName = "Loading...";
  String userClass = "...";

  @override
  void initState() {
    super.initState();
    fetchUserData();
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
                // 'WelcomeScreen' ki jagah apni login screen ka naam dein
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

  // Firestore se data fetch karne ka function
  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            userName = data.containsKey('name') ? data['name'] : "Student";
            userClass = data.containsKey('class')
                ? data['class'].toString()
                : "No Class";
          });
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
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
                    // Dynamic Class Display
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
                      childAspectRatio: 1.4,
                      children: [
                        _buildDashboardCard(
                          icon: Icons.assignment_turned_in_outlined,
                          title: 'Attendance',
                          description: 'Submit daily student leave request.',
                          buttonText: 'Apply for Leave',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceAlertsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.campaign_outlined,
                          title: 'Announcements',
                          description: 'View all school and class notices.',
                          buttonText: 'View Notices',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ViewAnnouncementsScreen()),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.rate_review_outlined,
                          title: 'View Homework',
                          description:
                              'Check daily homework posted by teachers.',
                          buttonText: 'View Homework',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const StudentHomeworkListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.edit_calendar_outlined,
                          title: 'Leave Request',
                          description:
                              'Apply for leave easily and track your request status.',
                          buttonText: 'Send Request',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SendLeaveRequestPage()),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.assessment_outlined,
                          title: 'Monthly Reports',
                          description:
                              'Access progress and attendance reports.',
                          buttonText: 'View Reports',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const StudentReportViewScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard(
                          icon: Icons.report_problem_outlined,
                          title: 'Submit Complaints',
                          description:
                              'Draft and submit school-related issues.',
                          buttonText: 'Post Complaint',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SubmitComplaintPage()),
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
            'Student Dashboard',
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1D4ED8).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout
              ? Colors.redAccent
              : (isSelected ? const Color(0xFF1D4ED8) : Colors.black54),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout
                ? Colors.redAccent
                : (isSelected ? const Color(0xFF1D4ED8) : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () async {
          Navigator.pop(context); // Drawer band karein
          if (title == 'Profile') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (title == 'Logout') {
            _showLogoutDialog(context);
          }
        },
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
                'STUDENT DASHBOARD',
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Icon(icon, size: 36, color: const Color(0xFF1D4ED8)),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
