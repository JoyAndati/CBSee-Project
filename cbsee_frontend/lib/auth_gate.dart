import 'package:cbsee_frontend/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/discoveries_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/teacher_dashboard_screen.dart'; // Ensure this screen exists

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not signed in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // User is signed in, now check if they have a profile on our backend
        return FutureBuilder<Map<String, dynamic>>(
          future: AuthService().checkProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (profileSnapshot.hasError || !profileSnapshot.hasData) {
              return Scaffold(
                body: Center(
                  child: Text("Error checking profile. Please restart the app."),
                ),
              );
            }

            final data = profileSnapshot.data!;
            final bool profileExists = data['profileExists'] ?? false;

            if (profileExists) {
              final String userType = data['userType'];
              if (userType == 'teacher') {
                return const MyClassroomScreen(); // Navigate to teacher dashboard
              } else {
                return const ScanScreen(); // Navigate to student dashboard/scan screen
              }
            } else {
              // User is authenticated with Firebase but has no profile in our DB
              return const CreateProfileScreen();
            }
          },
        );
      },
    );
  }
}