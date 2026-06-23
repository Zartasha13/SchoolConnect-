import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_connect/screens/teacher_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // USER LOGIN CHECK
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAEAEA),
        elevation: 0,
        centerTitle: true,

        iconTheme: const IconThemeData(color: Colors.black),

        title: const Text(
          'PROFILE',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      // ================= DRAWER =================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,

          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2E52D1)),

              child: Center(
                child: Text(
                  'SchoolConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),

              title: const Text('Dashboard'),

              onTap: () {
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,

                  MaterialPageRoute(
                    builder: (context) => const TeacherDashboardScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get(),

        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // DOCUMENT NOT FOUND
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found'));
          }

          // DATA FETCH
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          print(currentUser.uid);
          print(data);

          // SAFE FETCHING
          String name =
              (data['name'] ??
                      data['Name'] ??
                      data['name '] ??
                      data['fullName'] ??
                      data['username'] ??
                      '')
                  .toString();
          String role = data['role']?.toString() ?? '';

          String userClass = data['class']?.toString() ?? '';

          String email = data['email']?.toString() ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                // ================= HEADER =================
                Container(
                  width: double.infinity,
                  color: const Color(0xFF2E52D1),

                  padding: const EdgeInsets.symmetric(vertical: 25),

                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,

                        child: Icon(
                          Icons.person,
                          size: 55,
                          color: Color(0xFF2E52D1),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // USER NAME
                      Text(
                        name.isEmpty ? 'No Name' : name,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ================= NAME =================
                buildTile(icon: Icons.person, title: 'Name', value: name),

                const SizedBox(height: 25),

                // ================= ROLE =================
                buildTile(
                  icon: Icons.workspace_premium,
                  title: 'Role',
                  value: role,
                ),

                const SizedBox(height: 25),

                // ================= CLASS =================
                buildTile(icon: Icons.school, title: 'Class', value: userClass),

                const SizedBox(height: 25),

                // ================= EMAIL =================
                buildTile(icon: Icons.email, title: 'Email', value: email),

                const SizedBox(height: 35),

                // ================= CHANGE PASSWORD =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),

                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Color(0xFF2E52D1)),

                      const SizedBox(width: 15),

                      GestureDetector(
                        onTap: () {
                          // CHANGE PASSWORD SCREEN
                        },

                        child: const Text(
                          'Change Password',

                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================= REUSABLE TILE =================

Widget buildTile({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30),

    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, color: const Color(0xFF2E52D1), size: 28),

        const SizedBox(width: 20),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,

              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),

            const SizedBox(height: 3),

            Text(
              value.isEmpty ? 'Not Available' : value,

              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    ),
  );
}
