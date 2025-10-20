import 'dart:convert';
import 'package:cbsee_frontend/services/auth_service.dart';
import 'package:cbsee_frontend/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Model for Student data
class Student {
  final String studentID;
  final String name;
  final String gradeLevel;

  Student({required this.studentID, required this.name, required this.gradeLevel});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentID: json['StudentID'],
      name: json['Name'],
      gradeLevel: json['GradeLevel'],
    );
  }
}

class MyClassroomScreen extends StatefulWidget {
  @override
  _MyClassroomScreenState createState() => _MyClassroomScreenState();
}

class _MyClassroomScreenState extends State<MyClassroomScreen> {
  List<Student> _students = [];
  bool _isLoading = true;

  AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // Function to fetch dashboard data from the backend
  Future<void> _fetchDashboardData() async {
    // Replace with your actual token and URL
    String? token = await _authService.getToken(); 
    const String url = '$kBaseApiUrl/dashboard/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'token': token!},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['students'];
        setState(() {
          _students = data.map((json) => Student.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to show the add student modal
  void _showAddStudentModal() {
    final TextEditingController emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Student Email'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _addStudent(emailController.text);
                  Navigator.pop(context);
                },
                child: Text('Add Student'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to add a student by email
  Future<void> _addStudent(String email) async {
    // Replace with your actual token and URL
    String? token = await _authService.getToken(); 
    const String url = '$kBaseApiUrl/add_student/'; 

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'token': token!, 'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 201) {
        _fetchDashboardData(); // Refresh the dashboard
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0FFF0),
      appBar: AppBar(
        title: Text('My Classroom'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('Ms. Davison'),
                SizedBox(width: 8),
                CircleAvatar(
                  // Add your image asset
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      // Add your image asset
                    ),
                    title: Text(student.name),
                    subtitle: Text('Grade ${student.gradeLevel}'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentModal,
        child: Icon(Icons.add),
      ),
    );
  }
}