import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_connect/screens/admin_announcement_screen.dart';
import 'package:school_connect/screens/manage_users_screen.dart';
import 'package:school_connect/screens/resolve_complainrs_screen.dart';
import 'package:school_connect/screens/welcome_screen.dart';
import 'package:school_connect/screens/admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Logout Confirmation Dialog ---
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
              // 1. Firebase se sign out karein
              await FirebaseAuth.instance.signOut();

              // 2. Navigator.pushAndRemoveUntil ka sahi use karein
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) =>
                      false, // Ye pichli saari screens ko remove kar dega
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.5,
                children: [
                  _buildDashboardCard(
                    icon: Icons.people_alt_outlined,
                    title: 'Manage Users',
                    description: 'Manage accounts for Teachers and Students.',
                    buttonText: 'View All Users',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageUsersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.campaign_outlined,
                    title: 'Post Announcements',
                    description: 'Post updates, school notices, and news.',
                    buttonText: 'New Post',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminAnnouncementsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.assignment_late_outlined,
                    title: 'Manage Complaints',
                    description:
                        'Review and track submissions from parents or staff.',
                    buttonText: 'View Complaints',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminComplaintsPage()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Generate Chalan',
                    description:
                        'Calculate student fees and print chalan slips.',
                    buttonText: 'Create Chalan',
                    onPressed: () {},
                  ),
                  _buildDashboardCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Verify Chalan',
                    description: 'Cross-check paid receipts and update status.',
                    buttonText: 'Verify Now',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
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
            'Admin Dashboard',
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1D4ED8).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
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
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (title == 'Profile') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProfileScreen(),
              ),
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
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20), // School Green Color
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 16),
              const Text(
                'ADMIN DASHBOARD',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Welcome, Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                radius: 18,
                child: const Text('🧑‍💼', style: TextStyle(fontSize: 18)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Icon(icon, size: 40, color: const Color(0xFF1D4ED8)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
