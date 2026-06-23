import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ADMIN PROFILE',
            style: TextStyle(color: Colors.black54)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Admin data not found."));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // Role check: Sirf Admin ko hi data dikhaye
          if (userData['role'] != 'Admin') {
            return const Center(
                child: Text("Access Denied: Only Admins allowed."));
          }

          String currentName = userData['name'] ?? 'Admin';
          if (!_isEditing) _nameController.text = currentName;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: const Color(0xFF0D47A1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 70, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(height: 10),
                      Text(currentName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const Text('System Administrator',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        "Name",
                        _isEditing
                            ? TextField(controller: _nameController)
                            : Text(currentName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w500)),
                        _isEditing ? Icons.save : Icons.edit,
                        () {
                          if (_isEditing) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user?.uid)
                                .update({'name': _nameController.text});
                          }
                          setState(() => _isEditing = !_isEditing);
                        },
                      ),
                      _buildInfoCard(
                        "Email",
                        Text(user?.email ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                        null,
                        null,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showChangePasswordDialog(),
                          icon:
                              Icon(Icons.lock_outline, color: Colors.blue[800]),
                          label: Text('Change Password',
                              style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 16,
                                  decoration: TextDecoration.underline)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
      String label, Widget content, IconData? icon, VoidCallback? onPressed) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey)),
                  const SizedBox(height: 5),
                  content,
                ],
              ),
            ),
            if (icon != null)
              IconButton(
                  icon: Icon(icon, color: Colors.blue[800]),
                  onPressed: onPressed),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool isObscure = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: newPassController,
                  obscureText: isObscure,
                  decoration: const InputDecoration(hintText: "New password")),
              const SizedBox(height: 10),
              TextField(
                  controller: confirmPassController,
                  obscureText: isObscure,
                  decoration:
                      const InputDecoration(hintText: "Confirm password")),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (newPassController.text == confirmPassController.text &&
                    newPassController.text.length >= 6) {
                  await user?.updatePassword(newPassController.text);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
