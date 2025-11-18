import 'package:cbsee_frontend/utils/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 🔥 IMPORTANT: Replace with your actual backend URL
const String backendUrl = "http://192.168.100.44:8000/api/v1"; // Use 10.0.2.2 for Android emulator

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- Firebase Authentication Methods ---

  getAuth(){
    return _auth;
  }
  Future<User?> signInWithGoogle() async {
    try {
      // Use popup/redirect for web, native flow for mobile
      if (kIsWeb) {
        // Web: Use signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        try {
          // Try popup first (better UX)
          final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
          return userCredential.user;
        } catch (e) {
          // If popup fails (blocked), fall back to redirect
          debugPrint("Popup blocked, using redirect: $e");
          await _auth.signInWithRedirect(googleProvider);
          // Note: After redirect, user will return to app and we get result via getRedirectResult
          return null;
        }
      } else {
        // Mobile/Desktop: Use native Google Sign-In
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // User canceled the sign-in
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // Call this method on web app initialization to handle redirect result
  Future<User?> checkRedirectResult() async {
    if (kIsWeb) {
      try {
        final UserCredential? userCredential = await _auth.getRedirectResult();
        return userCredential?.user;
      } catch (e) {
        debugPrint("Redirect Result Error: $e");
        return null;
      }
    }
    return null;
  }

  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification(); // Firebase handles this now
      }
      return user;
    } catch (e) {
      debugPrint("Email Sign-Up Error: $e");
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null && !result.user!.emailVerified) {
         // Optionally prompt the user to check their email
         debugPrint("Email not verified.");
      }
      debugPrint("Logged in");
      return result.user;
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // --- Backend Profile Methods ---

  Future<Map<String, dynamic>> checkProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'profileExists': false};
    }

    final token = await user.getIdToken();
    final url = Uri.parse('$backendUrl/auth/check_profile/');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Handle server errors
        return {'profileExists': false, 'error': 'Server error'};
      }
    } catch (e) {
      // Handle network errors
      return {'profileExists': false, 'error': 'Network error'};
    }
  }

  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final token = await user.getIdToken();
    final url = Uri.parse('$BaseApiUrl/auth/signup/');

    // Add token and default name to the body
    profileData['token'] = token;
    profileData['name'] = user.displayName ?? profileData['name'] ?? 'No Name';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );
      // 201 Created or 200 OK (if user already existed, which shouldn't happen in this flow)
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("Create Profile Error: $e");
      return false;
    }
  }

  Future<String?> getToken() async {
    final token = await _auth.currentUser?.getIdToken();
    return token;
  }
}