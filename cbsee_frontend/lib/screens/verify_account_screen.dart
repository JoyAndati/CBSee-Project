import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';

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

  Future<void> _checkVerified() async {
    setState(() => _isLoading = true);
    final bool verified = await _authService.reloadAndCheckEmailVerified();
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified!')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not verified yet. Please check your inbox.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _isLoading ? null : () { _checkVerified(); },
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