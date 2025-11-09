import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  Future<void> _handleLogin(Future<dynamic> Function() loginMethod) async {
    setState(() => _isLoading = true);
    final user = await loginMethod();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
    }
    // On success, the AuthGate will automatically handle navigation.
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
                const Text('CBSee', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: secondaryColor)),
                const SizedBox(height: 16),
                const Text('Welcome Back!', style: TextStyle(fontSize: 24, color: secondaryColor)),
                const SizedBox(height: 40),
                CustomTextField(controller: _emailController, hintText: 'Email Address', icon: Icons.email_outlined),
                CustomTextField(controller: _passwordController, hintText: 'Password', icon: Icons.lock_outline, isPassword: true),
                const SizedBox(height: 20),
                CustomButton(
                  text: _isLoading ? 'Signing In...' : 'Log In',
                  onPressed: _isLoading ? null : () => _handleLogin(() => _authService.signInWithEmail(_emailController.text, _passwordController.text)),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR')),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _handleLogin(_authService.signInWithGoogle),
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
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