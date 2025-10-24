import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/colors.dart';

class TeacherSignupScreen extends StatefulWidget {
  const TeacherSignupScreen({super.key});

  @override
  State<TeacherSignupScreen> createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<TeacherSignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService(); // <-- FIX: Added AuthService instance
  bool _agreeToTerms = false;
  bool _isLoading = false; // <-- FIX: Added isLoading state
  String? _selectedGrade;
  String? _selectedSubject;

  // FIX: Added signup logic
  Future<void> _createTeacherAccount() async {
    final String fullName = _fullNameController.text.trim();
    final String email = _schoolEmailController.text.trim();
    final String password = _passwordController.text;
    final String confirm = _confirmPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty || _selectedGrade == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Terms and Privacy Policy.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.signUpWithEmailAndPassword(email, password, fullName);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (user != null) {
      // the teacher endpoint shall be called b
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please check your email to verify.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/verify', (route) => false, arguments: {'type':'teacher', 'gradeLevel':_selectedGrade, 'school':_schoolNameController.text, 'subject':_selectedSubject});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed. The email might be in use or invalid.')),
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
                const SizedBox(height: 16),
                const Text(
                  'Sign Up as a Teacher',
                  style: TextStyle(fontSize: 24, color: secondaryColor),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  hintText: 'Full Name',
                  icon: Icons.person_outline,
                  controller: _fullNameController,
                ),
                CustomTextField(
                  hintText: 'School Name',
                  icon: Icons.school_outlined,
                  controller: _schoolNameController,
                ),
                CustomTextField(
                  hintText: 'School Email Address',
                  icon: Icons.email_outlined,
                  controller: _schoolEmailController,
                ),
                CustomTextField(
                  hintText: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                ),
                CustomTextField(
                  hintText: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _confirmPasswordController,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: textFieldBackgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(border: InputBorder.none),
                    hint: const Text('Grade Level Taught'),
                    initialValue: _selectedGrade,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGrade = newValue;
                      });
                    },
                    items: <String>['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: textFieldBackgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(border: InputBorder.none),
                    hint: const Text('Subject Taught'),
                    initialValue: _selectedSubject,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                    },
                    items: <String>['Math', 'Science', 'English', 'History']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value!;
                        });
                      },
                      activeColor: primaryColor,
                    ),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(color: primaryColor),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: _isLoading ? 'Creating Account...' : 'Create Teacher Account', // <-- FIX: Updated text
                  onPressed: _isLoading ? null : _createTeacherAccount, // <-- FIX: Wired up onPressed
                ),
                 const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                         Navigator.pushNamed(context, '/login');
                      },
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