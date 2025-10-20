import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Google Sign-In configuration
  // For web, the plugin will automatically use the correct client ID from Firebase
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Helper for ActionCodeSettings
  ActionCodeSettings _getActionCodeSettings() {
    return ActionCodeSettings(
      // Use your Firebase project domain
      url: 'https://cbsee-1f435.firebaseapp.com/__/auth/action',
      handleCodeInApp: true,
      // Use your actual iOS bundle ID from firebase_options.dart
      iOSBundleId: 'com.example.cbseeFrontend',
      // Use your actual Android package name
      androidPackageName: 'com.example.cbsee_frontend',
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );
  }

  // Sign up with email and password
  Future<User?> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(fullName);
        await user.sendEmailVerification(_getActionCodeSettings()); // <-- FIX: Added ActionCodeSettings
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('signUpWithEmailAndPassword error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // Resend email verification
  Future<bool> sendVerificationEmail() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(_getActionCodeSettings()); // <-- FIX: Added ActionCodeSettings
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('sendVerificationEmail error: $e');
      return false;
    }
  }

  // Reload user and check if email is verified
  Future<bool> reloadAndCheckEmailVerified() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint('reloadAndCheckEmailVerified error: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      
      if (user != null) {
        // Check if email is verified
        if (!user.emailVerified) {
          return {
            'success': false,
            'error': 'Please verify your email before signing in. Check your inbox for a verification link.',
            'needsVerification': true,
            'user': user,
          };
        }
        
        return {
          'success': true,
          'user': user,
          'error': null,
        };
      }
      
      return {
        'success': false,
        'error': 'Login failed. Please try again.',
        'user': null,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed. Please try again.';
      }
      
      debugPrint('signInWithEmailAndPassword error: ${e.message}');
      return {
        'success': false,
        'error': errorMessage,
        'user': null,
      };
    } catch (e) {
      debugPrint('signInWithEmailAndPassword error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
        'user': null,
      };
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: _getActionCodeSettings(),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('sendPasswordResetEmail error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('sendPasswordResetEmail error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign in error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return null;
    }
  }
  Future<String?> getToken() async{
    String? token = await _auth.currentUser?.getIdToken();
    return token;
  }
}