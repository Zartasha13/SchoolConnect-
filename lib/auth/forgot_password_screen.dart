import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String userRole; // 'admin', 'teacher', ya 'student' pass karne ke liye

  const ForgotPasswordScreen({super.key, required this.userRole});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light professional background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 70,
        title: const Text(
          "Forgot Password",
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // 1. Center Icon (Fingerprint/Lock Box)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withOpacity(.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 42,
                    color: const Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Heading Text
                const Text(
                  'Forgot Your Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  "Enter your registered email address.\nWe'll send you a password reset link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 40),

                // 3. Email Custom Input Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF1E3A5F),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                          color: Color(0xFF1E3A5F),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Reset link Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: () async {
                      // 1. Controller se input email uthao aur spaces trim karo
                      String enteredEmail = _emailController.text.trim();

                      if (enteredEmail.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter your email"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        print("🔍 Firestore mein email check ho rahi hai...");

                        // 1. Check karein ke user database mein registered hai ya nahi
                        var userQuery = await FirebaseFirestore.instance
                            .collection('users')
                            .where('email', isEqualTo: enteredEmail)
                            .get();

                        // 2. Agar email nahi milti (Database khali aata hai)
                        if (userQuery.docs.isEmpty) {
                          print("❌ User Not Found!");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error: User Not Found!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        // 3. Agar email mil jati hai, toh reset link bhejein
                        else {
                          print("✅ User Found! Sending link...");
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: enteredEmail,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Reset link sent successfully! Please check your email.",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        print("❌ Error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Something went wrong: ${e.toString()}",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Back to Login Text Button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
                  label: const Text(
                    "Back to Login",
                    style: TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
