import 'package:cbsee_frontend/services/auth_service.dart';
import 'package:cbsee_frontend/widgets/custom_button.dart';
import 'package:cbsee_frontend/widgets/custom_textfield.dart';
import 'package:cbsee_frontend/utils/colors.dart';
import 'package:flutter/material.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _userType = 'student'; 

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  
  // Dropdown Values
  String? _selectedGrade;
  String? _selectedSubject;
  
  final List<String> _grades = ['Kindergarten', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];
  final List<String> _subjects = ['General', 'Science', 'Math', 'English', 'Art'];

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google Auth if available
    final user = _authService.getAuth().currentUser;
    if (user?.displayName != null) {
      _nameController.text = user!.displayName!;
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a grade level')));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> profileData = {
      'type': _userType,
      'name': _nameController.text.trim(),
      'gradeLevel': _selectedGrade, 
    };

    if (_userType == 'student') {
      profileData['schoolId'] = _schoolIdController.text.trim();
    } else {
      profileData['school'] = _schoolNameController.text.trim();
      profileData['subject'] = _selectedSubject ?? 'General';
    }

    final success = await _authService.createProfile(profileData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (_userType == 'teacher') {
        Navigator.pushNamedAndRemoveUntil(context, '/teacher_dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/scan', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create profile. Please check your connection.')),
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Complete Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: secondaryColor)),
                  const SizedBox(height: 10),
                  const Text('Tell us a bit about yourself.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(Icons.face)),
                      ButtonSegment(value: 'teacher', label: Text('Teacher'), icon: Icon(Icons.school)),
                    ],
                    selected: {_userType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _userType = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return primaryColor.withOpacity(0.2);
                          }
                          return Colors.transparent;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  CustomTextField(controller: _nameController, hintText: 'Full Name', icon: Icons.person),

                  const SizedBox(height: 10),
                  _buildDropdown(
                    hint: "Select Grade Level",
                    value: _selectedGrade,
                    items: _grades,
                    onChanged: (val) => setState(() => _selectedGrade = val),
                    icon: Icons.stairs
                  ),

                  if (_userType == 'student')
                    ..._buildStudentFields()
                  else
                    ..._buildTeacherFields(),
                  
                  const SizedBox(height: 30),
                  CustomButton(
                    text: _isLoading ? 'Saving...' : 'Get Started',
                    onPressed: _isLoading ? null : _submitProfile,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      await _authService.signOut();
                      if(mounted) Navigator.pop(context);
                    },
                    child: const Text('Cancel / Log Out', style: TextStyle(color: Colors.grey)),
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
      CustomTextField(controller: _schoolIdController, hintText: 'School ID (Optional)', icon: Icons.badge),
    ];
  }

  List<Widget> _buildTeacherFields() {
    return [
      CustomTextField(controller: _schoolNameController, hintText: 'School Name', icon: Icons.location_city),
      const SizedBox(height: 10),
      _buildDropdown(
        hint: "Select Subject",
        value: _selectedSubject,
        items: _subjects,
        onChanged: (val) => setState(() => _selectedSubject = val),
        icon: Icons.book
      ),
    ];
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: textFieldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: Text(hint),
                value: value,
                isExpanded: true,
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}