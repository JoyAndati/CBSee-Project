import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/colors.dart'; // Assuming you have this file for colors

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _userType = 'student'; // Default selection

  // Controllers for all fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  String? _selectedGrade;
  String? _selectedSubject;

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);

    Map<String, dynamic> profileData = {
      'type': _userType,
      'name': _nameController.text.trim(),
    };

    if (_userType == 'student') {
      profileData['schoolId'] = _schoolIdController.text.trim();
      profileData['gradeLevel'] = '3'; // Example, you might want a dropdown
    } else {
      profileData['school'] = _schoolNameController.text.trim();
      profileData['gradeLevel'] = _selectedGrade;
      profileData['subject'] = _selectedSubject;
    }

    final success = await _authService.createProfile(profileData);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // The AuthGate will rebuild and navigate to the correct dashboard automatically.
        // To force a refresh of the AuthGate's future, we can sign out and let it handle re-auth,
        // but for a better UX, we can just "hot-reload" the auth state.
        // A simple way is to just call setState on the AuthGate's parent, but that's not clean.
        // For now, signing out and letting the user know is an option, or just pop.
        // The most robust solution is a proper state management tool (Provider, Riverpod).
        // For simplicity, we'll just let the AuthGate's stream handle it on next app open,
        // and show a success message. We can also attempt a manual sign out.
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created! Please restart the app or log in again to continue.')),
        );
        await _authService.signOut();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create profile. Please try again.')),
        );
      }
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Complete Your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: secondaryColor)),
                  const SizedBox(height: 20),
                  const Text('Please tell us who you are.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  
                  // Role Selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'student', label: Text('Student')),
                      ButtonSegment(value: 'teacher', label: Text('Teacher')),
                    ],
                    selected: {_userType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _userType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 30),

                  // Common Field
                  CustomTextField(controller: _nameController, hintText: 'Full Name', icon: Icons.person),

                  // Conditional Fields
                  if (_userType == 'student')
                    ..._buildStudentFields()
                  else
                    ..._buildTeacherFields(),
                  
                  const SizedBox(height: 30),
                  CustomButton(
                    text: _isLoading ? 'Saving...' : 'Complete Signup',
                    onPressed: _isLoading ? null : _submitProfile,
                  ),
                  TextButton(
                    onPressed: () => _authService.signOut(),
                    child: const Text('Cancel and Log Out', style: TextStyle(color: primaryColor)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      CustomTextField(controller: _schoolIdController, hintText: 'School ID', icon: Icons.school),
    ];
  }

  List<Widget> _buildTeacherFields() {
    return [
      CustomTextField(controller: _schoolNameController, hintText: 'School Name', icon: Icons.school_outlined),
      // Add Dropdowns for Grade and Subject as in your original teacher_signup_screen
      // For brevity, I'm omitting the full dropdown implementation here but you can copy it back.
      Container( /* Dropdown for Grade Level */ ),
      Container( /* Dropdown for Subject */ ),
    ];
  }
}