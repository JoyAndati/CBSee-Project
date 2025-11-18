import 'package:cbsee_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentIndex = 2;
  final AuthService _authService = AuthService();

  void _onTabTapped(int index) {
    if (_currentIndex == index) return; // Do nothing if already on the same tab

    setState(() {
      _currentIndex = index;
    });

    // Navigate to different screens based on tab selection
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/scan');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        // Already on settings screen
        break;
    }
  }

  // --- Logout Functionality ---
  Future<void> _logout() async {
    await _authService.signOut();
    // Navigate to login screen and remove all previous routes from the stack
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar (unchanged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer for centering
                ],
              ),
            ),

            // Main content area - Now with a settings list
            Expanded(
              child: ListView(
                children: [
                  _buildSettingsCategory("Account"),
                  _buildSettingsItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      // Navigate to Edit Profile screen
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {
                      // Navigate to Change Password screen
                    },
                  ),
                  _buildSettingsCategory("General"),
                   _buildSettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      // Navigate to Notifications settings
                    },
                  ),
                   _buildSettingsItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    onTap: () {
                      // Navigate to Language settings
                    },
                  ),
                  const SizedBox(height: 20),
                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextButton(
                      onPressed: _logout,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF3A3A3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.camera_alt,
              label: 'Scan',
              isActive: _currentIndex == 0,
              onTap: () => _onTabTapped(0),
            ),
            _buildNavItem(
              icon: Icons.history,
              label: 'History',
              isActive: _currentIndex == 1,
              onTap: () => _onTabTapped(1),
            ),
            _buildNavItem(
              icon: Icons.settings,
              label: 'Settings',
              isActive: _currentIndex == 2,
              onTap: () => _onTabTapped(2),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable UI Widgets ---

  Widget _buildSettingsCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, // Giving a fixed width for better spacing
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primaryColor : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryColor : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}