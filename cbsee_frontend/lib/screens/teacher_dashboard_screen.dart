import 'dart:convert';
import 'package:cbsee_frontend/services/auth_service.dart';
import 'package:cbsee_frontend/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cbsee_frontend/screens/student_progress_screen.dart';

// Model for Student data
class Student {
  final String studentID;
  final String name;
  final String gradeLevel;
  final String lastActive;
  final int objectsFound;
  final String avatarUrl;

  Student({
    required this.studentID,
    required this.name,
    required this.gradeLevel,
    required this.lastActive,
    required this.objectsFound,
    required this.avatarUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentID: json['StudentID'],
      name: json['Name'],
      gradeLevel: json['GradeLevel'],
      lastActive: json['lastActive'] ?? 'Never',
      objectsFound: json['objectsFound'] ?? 0,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=${json['StudentID']}',
    );
  }
}

class MyClassroomScreen extends StatefulWidget {
  const MyClassroomScreen({super.key});
  @override
  _MyClassroomScreenState createState() => _MyClassroomScreenState();
}

class _MyClassroomScreenState extends State<MyClassroomScreen> {
  List<Student> _students = [];
  bool _isLoading = true;

  final AuthService _authService = AuthService();
  String? _name;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    String? token = await _authService.getToken();
    if (token == null) return;
    
    const String url = '$BaseApiUrl/dashboard/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> studentsList = data['students'];
        _name = data['name'];
        if(mounted) {
          setState(() {
            _students = studentsList.map((json) => Student.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        if(mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      print("Error fetching dashboard: $e");
    }
  }

  void _showAddStudentModal() {
    final TextEditingController emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Student Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (emailController.text.isNotEmpty) {
                    _addStudent(emailController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Student'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addStudent(String email) async {
    String? token = await _authService.getToken();
    const String url = '$BaseApiUrl/add_student/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': "Bearer $token", 'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 201) {
        _fetchDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student Added!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add student (Check email)')));
      }
    } catch (e) {
      print(e);
    }
  }
  
  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F7E9),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty 
                    ? const Center(child: Text("No students yet. Add one!"))
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return _buildStudentCard(student);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentModal,
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Classroom',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          Row(
            children: [
              Text(
                _name ?? 'Teacher',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 26),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
         onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentProgressScreen(student: student),
            ),
          );
        },
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF28A745),
                child: CircleAvatar(
                  radius: 27,
                  backgroundImage: NetworkImage(student.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.gradeLevel,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (student.objectsFound > 0)
                      Text(
                        'Found Today: ${student.objectsFound}',
                        style: const TextStyle(color: Color(0xFF28A745), fontWeight: FontWeight.w600),
                      )
                    else
                      Text(
                        'Active: ${student.lastActive}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      )),
    );
  }
}