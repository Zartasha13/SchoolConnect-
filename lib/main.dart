import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_connect/screens/student_dashboard_screen.dart';
import 'package:school_connect/screens/teacher_dashboard_screen.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'package:school_connect/screens/admin_dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase init ho gaya!");
  } catch (e) {
    print("Firebase FATAL ERROR: $e"); // Yahan check karein ki kya error hai
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SchoolConnect',
      theme: AppTheme.lightTheme,
      // main.dart ke andar MyApp class mein:
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Agar connection abhi process ho raha hai
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          // 2. Agar user logged in hai
          else if (snapshot.hasData) {
            return RoleBasedNavigator(user: snapshot.data!);
          }

          // 3. Agar user waqai logged out hai
          else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}

class RoleBasedNavigator extends StatelessWidget {
  final User user;
  const RoleBasedNavigator({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          String role = snapshot.data!.get('role').toString().toLowerCase();
          if (role == 'admin') return const AdminDashboardScreen();
          if (role == 'teacher') return const TeacherDashboardScreen();
          if (role == 'student') return const StudentDashboardScreen();
        }
        return const WelcomeScreen(); // Agar role match na ho
      },
    );
  }
}
