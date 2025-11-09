import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:cbsee_frontend/services/auth_service.dart';
import 'package:cbsee_frontend/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../utils/colors.dart';
import '../widgets/object_detection_modal.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // --- Camera State ---
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final AuthService _authService = AuthService();

  // --- TTS State ---
  final FlutterTts _flutterTts = FlutterTts();
  String? _lastPrediction;
  String? _lastDescription;

  // --- UI State ---
  int _currentIndex = 0;
  bool _isInferencing = false;

  // --- Backend API Endpoint ---
  static const String _apiUrl = "$BaseApiUrl/classify/";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTts();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) return;

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  // Simplified TTS initialization
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakPrediction(String prediction, String description) async {
    try {
      await _flutterTts.stop();
      String textToSpeak = "I found a $prediction. $description";
      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _onTabTapped(int index, Map args) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(
          context,
          '/dashboard',
          arguments: args
        );
        break;
      case 1:
        Navigator.pushNamed(
          context,
          '/dashboard',
          arguments: args
        );
        break;
      case 2:
        Navigator.pushNamed(context, '/settings', arguments: args);
        break;
    }
  }

  /// Captures image, sends it to backend, and displays the result.
  Future<void> _captureAndClassify() async {
    if (_isInferencing || !_isCameraInitialized || _cameraController == null) {
      return;
    }

    if (mounted) setState(() => _isInferencing = true);
    String? token = await _authService.getToken(); 
    Map<String, dynamic> body = {
      'token': token,
    };

    String jsonBody = json.encode(body);

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.fields['body'] = jsonBody;
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String prediction = responseData['prediction'];
        final String description = responseData['description'];
        
        // Store last prediction
        _lastPrediction = prediction;
        _lastDescription = description;
        
        // Show the modal first
        _showObjectDetectionModal(prediction, description);
        
        // Then, speak the prediction
        await _speakPrediction(prediction, description);
        
      } else {
        debugPrint('Server error: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error from server: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInferencing = false);
    }
  }

  void _showObjectDetectionModal(String objectName, String objectDescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ObjectDetectionModalWithTTS(
        // Pass the TTS instance to the modal
        flutterTts: _flutterTts,
        objectName: objectName,
        learningTip: objectDescription,
        // -- Other parameters remain the same --
        category: 'Identified Object',
        gradeLevel: 'Grade 1 & 2',
        foundCount: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled = !_isCameraInitialized || _isInferencing;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final user = args?['user'];
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    'Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Search functionality
                    },
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF3A3A3A),
                child: Stack(
                  children: [
                    // Camera preview or placeholder
                    if (_isCameraInitialized && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0xFF3A3A3A),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 64,
                            color: Color(0xFF6A6A6A),
                          ),
                        ),
                      ),

                    // Instruction bubble
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.25,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Point at an object!',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Target reticle
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.35,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.landscape,
                                  size: 40,
                                  color: Color(0xFF6A6A6A),
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 2,
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 30,
                                  height: 2,
                                  color: Colors.white,
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 2,
                                  height: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Capture Button
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.15,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: isButtonDisabled ? null : _captureAndClassify,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isButtonDisabled ? Colors.grey : Colors.white,
                              border: Border.all(
                                color: primaryColor,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isInferencing
                                  ? const CircularProgressIndicator(
                                      color: primaryColor,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primaryColor,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
              onTap: () => _onTabTapped(0, {'user':user}),
            ),
            _buildNavItem(
              icon: Icons.history,
              label: 'History',
              isActive: _currentIndex == 1,
              onTap: () => _onTabTapped(1, {'user':user}),
            ),
            _buildNavItem(
              icon: Icons.settings,
              label: 'Settings',
              isActive: _currentIndex == 2,
              onTap: () => _onTabTapped(2, {'user':user}),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
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