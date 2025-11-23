import 'dart:convert';
import 'package:cbsee_frontend/services/auth_service.dart';
import 'package:cbsee_frontend/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:cbsee_frontend/screens/teacher_dashboard_screen.dart'; // For Student Model
import 'package:http/http.dart' as http;
import '../models/discovery_item.dart';

class StudentProgressScreen extends StatefulWidget {
  final Student student;
  const StudentProgressScreen({super.key, required this.student});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  // Stats State
  bool _isLoading = true;
  int _totalDiscoveries = 0;
  int _weeklyDiscoveries = 0;
  String _mostFoundCategory = "None";
  Map<String, double> _chartData = {};
  List<DiscoveryItem> _recentHistory = [];
  
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    String? token = await _authService.getToken();
    final url = '$BaseApiUrl/student_stats/${widget.student.studentID}/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse Chart Data (Dynamic keys)
        Map<String, dynamic> rawChart = data['chart_data'] ?? {};
        Map<String, double> parsedChart = {};
        rawChart.forEach((key, value) {
          parsedChart[key] = (value as num).toDouble();
        });

        // Parse History
        List<dynamic> historyJson = data['history'] ?? [];
        List<DiscoveryItem> historyList = historyJson.map((e) => DiscoveryItem.fromJson(e)).toList();

        if (mounted) {
          setState(() {
            _totalDiscoveries = data['total_discoveries'] ?? 0;
            _weeklyDiscoveries = data['weekly_discoveries'] ?? 0;
            _mostFoundCategory = data['most_found_category'] ?? "None";
            _chartData = parsedChart;
            _recentHistory = historyList;
            _isLoading = false;
          });
        }
      } else {
        if(mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching stats: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F5), // Light cream background
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context, widget.student),
                  const SizedBox(height: 24),
                  _buildStatCards(),
                  const SizedBox(height: 24),
                  _buildProgressChart(),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Discoveries',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_recentHistory.isEmpty)
                    const Text("No recent discoveries.", style: TextStyle(color: Colors.grey))
                  else
                    ..._recentHistory.map((item) => _buildDiscoveryItem(item)).toList(),
                ],
              ),
            ),
          ),
      ),
    );
  }

  // Custom App Bar Widget
  Widget _buildAppBar(BuildContext context, Student student) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.green, size: 18),
              Text('Back', style: TextStyle(color: Colors.green, fontSize: 16)),
            ],
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(student.avatarUrl),
          backgroundColor: Colors.white,
        ),
        const SizedBox(width: 8),
        Text(
          "${student.name.split(' ')[0]}'s Progress", // Display first name
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
      ],
    );
  }

  // Top Statistics Cards
  Widget _buildStatCards() {
    return Column(
      children: [
        _buildStatCard('Total Objects Found', '$_totalDiscoveries'),
        const SizedBox(height: 12),
        _buildStatCard('Objects This Week', '$_weeklyDiscoveries'),
        const SizedBox(height: 12),
        _buildStatCard('Most Found Category', _mostFoundCategory, isCategory: true),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, {bool isCategory = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isCategory ? const Color(0xFF28A745) : Colors.black,
              fontSize: isCategory ? 22 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Progress by Category Bar Chart
  Widget _buildProgressChart() {
    // Generate colors dynamically
    final colors = [
      const Color(0xFFF9C74F),
      const Color(0xFF90BE6D),
      const Color(0xFF4D90F0),
      const Color(0xFFF94144),
      Colors.purpleAccent,
      Colors.teal,
    ];

    int colorIndex = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _chartData.isEmpty 
          ? const Center(child: Text("No data for chart", style: TextStyle(color: Colors.grey)))
          : SizedBox(
            height: 120, // Fixed height for the chart area
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _chartData.entries.map((entry) {
                final color = colors[colorIndex % colors.length];
                colorIndex++;
                return _buildBar(entry.key, entry.value, color);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double percentage, Color color) {
    // Ensure labels aren't too long for the chart
    String displayLabel = label.length > 8 ? "${label.substring(0,6)}.." : label;
    
    // Ensure height is at least a little bit visible if > 0
    double heightFactor = percentage < 0.1 && percentage > 0 ? 0.1 : percentage;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 100 * heightFactor, // Bar height based on percentage (max 100px)
          width: 35,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(displayLabel, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  // Recent Discovery List Item
  Widget _buildDiscoveryItem(DiscoveryItem item) {
    // Determine icon based on category or name (simplified logic)
    IconData icon = Icons.help_outline;
    if (item.category.contains("Kitchen")) icon = Icons.kitchen;
    if (item.category.contains("Bath")) icon = Icons.bathtub;
    if (item.name.toLowerCase().contains("apple")) icon = Icons.restaurant;
    
    // Format Date
    final now = DateTime.now();
    final diff = now.difference(item.discoveredDate);
    String timeStr = "";
    if (diff.inDays == 0) {
      timeStr = "Today";
    } else if (diff.inDays == 1) {
      timeStr = "Yesterday";
    } else {
      timeStr = "${diff.inDays} days ago";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Icon(icon, color: const Color(0xFF28A745), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          // Category tag
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Colors.grey[100],
               borderRadius: BorderRadius.circular(4)
             ),
             child: Text(item.category, style: const TextStyle(fontSize: 10, color: Colors.grey)),
           )
        ],
      ),
    );
  }
}