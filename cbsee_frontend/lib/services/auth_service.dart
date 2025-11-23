import 'package:cbsee_frontend/utils/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuth getAuth() {
    return _auth;
  }

  // Handles both Login and Signup for Google
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        try {
          final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
          return userCredential.user;
        } catch (e) {
          debugPrint("Popup blocked or failed, trying redirect: $e");
          await _auth.signInWithRedirect(googleProvider);
          return null;
        }
      } else {
        // Mobile flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // User cancelled
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      debugPrint("Google Auth Error: $e");
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
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
      return result.user;
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print("Sign out error: $e");
    }
  }

  // --- Backend Profile Methods ---

  Future<Map<String, dynamic>> checkProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'profileExists': false};
    }

    final token = await user.getIdToken();
    final url = Uri.parse('$BaseApiUrl/auth/check_profile/');
    
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
        return {'profileExists': false, 'error': 'Server error'};
      }
    } catch (e) {
      print("Check Profile Network Error: $e");
      return {'profileExists': false, 'error': 'Network error'};
    }
  }

  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final token = await user.getIdToken();
    final url = Uri.parse('$BaseApiUrl/auth/signup/');

    profileData['token'] = token;
    
    if (profileData['name'] == null || profileData['name'].isEmpty) {
      profileData['name'] = user.displayName ?? 'Unknown User';
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token' 
        },
        body: jsonEncode(profileData),
      );
      
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