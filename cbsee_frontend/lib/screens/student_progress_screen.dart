import 'package:flutter/material.dart';
import 'package:cbsee_frontend/screens/teacher_dashboard_screen.dart'; // Assuming Student model is here
class StudentProgressScreen extends StatelessWidget {
final Student student;
const StudentProgressScreen({super.key, required this.student});
@override
Widget build(BuildContext context) {
// Mock data for UI display
final progressData = {
'Kitchen': 0.9,
'Bedroom': 0.4,
'Bathroom': 0.6,
'Living Room': 0.5,
};
return Scaffold(
  backgroundColor: const Color(0xFFF9F9F5), // Light cream background
  body: SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context, student),
            const SizedBox(height: 24),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildProgressChart(progressData),
            const SizedBox(height: 24),
            const Text(
              'Recent Discoveries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDiscoveryItem(Icons.restaurant, 'Spoon', 'Today, 10:45 AM'),
            _buildDiscoveryItem(Icons.king_bed_outlined, 'Pillow', 'Yesterday'),
            _buildDiscoveryItem(Icons.wash, 'Toothbrush', '2 days ago'), // Using 'wash' as a proxy for toothbrush
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
_buildStatCard('Total Objects Found', '124'),
const SizedBox(height: 12),
_buildStatCard('Objects This Week', '21'),
const SizedBox(height: 12),
_buildStatCard('Most Found Category', 'Kitchen Items', isCategory: true),
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
Widget _buildProgressChart(Map<String, double> data) {
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
SizedBox(
height: 120, // Fixed height for the chart area
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
crossAxisAlignment: CrossAxisAlignment.end,
children: [
_buildBar('Kitchen', data['Kitchen']!, const Color(0xFFF9C74F)),
_buildBar('Bedroom', data['Bedroom']!, const Color(0xFF90BE6D)),
_buildBar('Bathroom', data['Bathroom']!, const Color(0xFF4D90F0)),
_buildBar('Living Room', data['Living Room']!, const Color(0xFFF94144)),
],
),
),
],
),
);
}
Widget _buildBar(String label, double percentage, Color color) {
return Column(
mainAxisAlignment: MainAxisAlignment.end,
children: [
Container(
height: 100 * percentage, // Bar height based on percentage
width: 35,
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(8),
),
),
const SizedBox(height: 8),
Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
],
);
}
// Recent Discovery List Item
Widget _buildDiscoveryItem(IconData icon, String title, String subtitle) {
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
Icon(icon, color: const Color(0xFF28A745), size: 28),
const SizedBox(width: 16),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
),
const SizedBox(height: 4),
Text(
subtitle,
style: const TextStyle(color: Colors.grey, fontSize: 14),
),
],
),
],
),
);
}
}