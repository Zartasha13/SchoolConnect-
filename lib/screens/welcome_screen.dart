import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'user_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF1746A2);
  static const Color lightGreen = Color(0xFF8BE3B3);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Responsive Width

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // ================= TOP SECTION =================
                  // === TOP SECTION (SIRF AIK DAFA RAKHEIN) ===
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Blue Background
                      Container(
                        height: 250,
                        width: double.infinity,
                        color: AppTheme.primaryBlue,
                      ),

                      // 2. White Curve
                      Positioned.fill(
                        top: 160,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(160),
                            ),
                          ),
                        ),
                      ),

                      // 3. Main Content (Welcome Text & Cap Icon - NO DUPLICATE)
                      Positioned(
                        top: 30,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome to SchoolConnect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 0),
                            const Icon(
                              Icons.school_outlined,
                              size: 120,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // --- SCHOOL IMAGE AREA ---
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Image.asset(
                      'assets/school.png',
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.fill,
                    ),
                  ),

                  const SizedBox(height: 35), // Buttons ke liye gap
                  // ================= TITLE =================
                  /*const Text(
                    'SCHOOLCONNECT',

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 15),*/

                  // ================= SCHOOL IMAGE =================
                  /*Image.asset(
                    'assets/school.png',

                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                  ),

                  const SizedBox(height: 15),*/

                  // ================= ADMIN LOGIN BUTTON =================
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLoginScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(
                      40,
                    ), // Taake click ka wave effect bhi rounded ho
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 75,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.18,
                              ), // Naya standard format error nahi dega
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.key,
                                color: Colors.white,
                                size: 38,
                              ), // Icon par const laga diya
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // --- Yahan FittedBox add kiya hai jo user login button ki tarah text ko responsive banayega ---
                                    FittedBox(
                                      fit: BoxFit
                                          .scaleDown, // Text bada hone par size automatic chota karega
                                      alignment: Alignment
                                          .centerLeft, // Text ko left side par align rakhega
                                      child: const Text(
                                        'LOGIN AS ADMIN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ================= USER LOGIN BUTTON =================
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserLoginScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(
                      40,
                    ), // Click effect ko rounded rakhne ke liye
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Container(
                        height: 75,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit,
                                color: Colors.black,
                                size: 36,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // --- Yahan FittedBox add kiya hai jo screen ke mutabiq text adjust karega ---
                                    FittedBox(
                                      fit: BoxFit
                                          .scaleDown, // Text bada hone par size automatic chota karega
                                      alignment: Alignment
                                          .centerLeft, // Text ko left side par align rakhega
                                      child: const Text(
                                        'LOGIN AS USER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    /*Row(
                    children: [
                      Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.black,
                        size: 20,
                      ),
                    ],
                  ),*/
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ================= INFO TEXT =================
                  /*const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),

                    child: Text(
                      'Admin, Teacher, or Student? Log in or request an account to get started.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),*/
                  const SizedBox(height: 40),

                  // ================= FOOTER =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    color: const Color.fromARGB(255, 181, 190, 201),
                    child: const Center(
                      child: Text(
                        'Connecting Education, Building Futures',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
