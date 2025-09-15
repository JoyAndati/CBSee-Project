import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email address and we\'ll send you a link to reset your password.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email address.')),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                setState(() => _isLoading = true);
                
                final bool sent = await _authService.sendPasswordResetEmail(email);
                setState(() => _isLoading = false);
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sent 
                        ? 'Password reset email sent to $email'
                        : 'Failed to send password reset email. Please try again.'),
                  ),
                );
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'CBSee',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: secondaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back, Joy!',
                  style: TextStyle(fontSize: 24, color: secondaryColor),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  hintText: 'Email or Phone Number',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                ),
                CustomTextField(
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPasswordDialog(),
                    child: const Text('Forgot Password?', style: TextStyle(color: primaryColor)),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: _isLoading ? 'Signing In...' : 'Log In',
                  onPressed: _isLoading ? null : () async {
                    final String email = _emailController.text.trim();
                    final String password = _passwordController.text;

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all fields.')),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    final result = await _authService.signInWithEmailAndPassword(email, password);
                    setState(() => _isLoading = false);

                    if (!mounted) return;
                    
                    if (result['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login successful!')),
                      );
                      // Navigate to main app or dashboard
                      // TODO: Replace with your main app route
                      Navigator.pushReplacementNamed(context, '/home');
                    } else if (result['needsVerification'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['error']),
                          action: SnackBarAction(
                            label: 'Verify',
                            onPressed: () => Navigator.pushNamed(context, '/verify'),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['error'])),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                // SizedBox(
                //   width: double.infinity,
                //   child: OutlinedButton.icon(
                //     onPressed: _isLoading ? null : () async {
                //       setState(() => _isLoading = true);
                //       final user = await _authService.signInWithGoogle();
                //       setState(() => _isLoading = false);

                //       if (!mounted) return;
                //       if (user != null) {
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           const SnackBar(content: Text('Google sign-in successful!')),
                //         );
                //         // Navigate to main app or dashboard
                //         // TODO: Replace with your main app route
                //         Navigator.pushReplacementNamed(context, '/home');
                //       } else {
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           const SnackBar(content: Text('Google sign-in failed. Please try again.')),
                //         );
                //       }
                //     },
                //     icon: const Icon(Icons.login, color: Colors.red),
                //     label: const Text('Continue with Google', style: TextStyle(color: Colors.black87)),
                //     style: OutlinedButton.styleFrom(
                //       padding: const EdgeInsets.symmetric(vertical: 16.0),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12.0),
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text('Sign Up', style: TextStyle(color: primaryColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}