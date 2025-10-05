import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({super.key});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _resendEmail() async {
    setState(() => _isLoading = true);
    final bool sent = await _authService.sendVerificationEmail();
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sent ? 'Verification email sent.' : 'Failed to send verification email.')),
    );
  }

  Future<void> _checkVerified(String type) async {
    setState(() => _isLoading = true);
    final bool verified = await _authService.reloadAndCheckEmailVerified();
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (verified) {
      // Here send to backend
      final User? user= _authService.getCurrentUser();
      if(user != null){
        final String? token = await user.getIdToken();
        // send to backend
      
        final Map<String, dynamic> body = {
          'token': token,
          'type': type, // "student" or "teacher"
        };
        try {
          print("here");
          // 🔥 Replace with your backend URL
          final url = Uri.parse('http://192.168.100.5:8000/api/v1/auth/signup/');
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          );
          print('sent: $response');

          if (response.statusCode == 200 || response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email verified!')),
            );
            print('✅ Signup success: ${response.body}');
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            print('❌ Signup failed (${response.statusCode}): ${response.body}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SignUp failed. Try again')),
            );
          }
        } catch (e) {
          print('Error sending request: $e');
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not verified yet. Please check your inbox.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final type = args?['type'];
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CBSee',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: secondaryColor),
                ),
                const SizedBox(height: 30),
                const Icon(Icons.mark_email_unread_outlined, size: 60, color: primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(fontSize: 24, color: secondaryColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We have sent a verification link to your email address. Please click the link to verify your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isLoading ? null : () { _resendEmail(); },
                  child: const Text('Resend Email', style: TextStyle(color: primaryColor)),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: _isLoading ? 'Please wait...' : 'I Verified, Continue',
                  onPressed: _isLoading ? null : () { _checkVerified(type); },
                  color: const Color(0xFF00E676),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}