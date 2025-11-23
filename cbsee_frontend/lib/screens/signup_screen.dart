import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _signUp() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Logging in...')),
      );
      // AuthGate handles the rest
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed. Email might be in use.')),
      );
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    
    if (!mounted) return;
    
    if (user != null) {
      // Success: AuthGate will detect user and redirect to CreateProfileScreen if needed
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else {
      setState(() => _isLoading = false);
      // User likely cancelled the popup
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Google Sign Up cancelled.')),
      // );
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
                const Text('Join CBSee', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: secondaryColor)),
                const SizedBox(height: 40),
                
                CustomTextField(controller: _nameController, hintText: 'Full Name', icon: Icons.person_outline),
                CustomTextField(controller: _emailController, hintText: 'Email Address', icon: Icons.email_outlined),
                CustomTextField(controller: _passwordController, hintText: 'Password', icon: Icons.lock_outline, isPassword: true),
                
                const SizedBox(height: 20),
                CustomButton(
                  text: _isLoading ? 'Creating account...' : 'Sign Up',
                  onPressed: _isLoading ? null : _signUp,
                ),
                
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR')),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Signup Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signUpWithGoogle,
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                  label: const Text('Sign up with Google'),
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red, // Google Red
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Log In', style: TextStyle(color: primaryColor)),
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