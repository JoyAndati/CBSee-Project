import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img; // Use a prefix to avoid name clashes
import 'package:permission_handler/permission_handler.dart';
import 'package:pytorch_mobile/enums/dtype.dart';
import 'package:pytorch_mobile/model.dart';
import 'package:pytorch_mobile/pytorch_mobile.dart';

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

  // --- UI State ---
  int _currentIndex = 0;

  // --- PyTorch Model & Inference State ---
  Model? _imageModel;
  List<String>? _labels;
  bool _isModelLoading = true;
  bool _isInferencing = false; // To prevent multiple captures at once

  // --- Constants for model and preprocessing ---
  // These must match your model's requirements
  static const String _modelPath = "assets/models/mobile_image_classifier.ptl";
  static const String _labelsPath = "assets/models/mobile_image_classifier_classes.txt";
  static const int _inputSize = 224;
  // These are the mean and std values from your Python training script's Normalize transform
  static const List<double> _means = [0.485, 0.456, 0.406];
  static const List<double> _stds = [0.229, 0.224, 0.225];

  @override
  void initState() {
    super.initState();
    // Initialize both camera and model
    _initializeCamera();
    _loadModel();
  }

  /// Loads the TorchScript Lite model and class labels from assets.
  Future<void> _loadModel() async {
    try {
      _imageModel = await PyTorchMobile.loadModel(_modelPath);
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n');
    } catch (e) {
      debugPrint('Error loading model or labels: $e');
      // Optionally show an error to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load the recognition model.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    }
  }

  /// Requests permissions and initializes the camera controller.
  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Camera permission not granted');
      return;
    }

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      debugPrint('No cameras available');
      return;
    }

    _cameraController = CameraController(
      _cameras![0], // Use the first available camera
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

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Handles navigation for the bottom bar.
  void _onTabTapped(int index) {
    if (_currentIndex == index) return; // Avoid rebuilding if already on the screen
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on scan screen
        break;
      case 1:
        // Use pushReplacementNamed to avoid building a stack of screens
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  /// Captures an image, preprocesses it, runs inference, and shows the result.
  Future<void> _captureAndInfer() async {
    // Prevent multiple inferences at the same time
    if (_isInferencing || !_isCameraInitialized || _cameraController == null) {
      return;
    }

    if (mounted) setState(() => _isInferencing = true);

    try {
      final XFile imageFile = await _cameraController!.takePicture();

      // Preprocess the image to match model input requirements
      final processedTensor = await _preprocessImage(imageFile);

      // Run inference
      // The shape must match the model's expected input: [1, 3, 224, 224]
      final prediction = await _imageModel!.getPrediction(
        processedTensor,
        [1, 3, _inputSize, _inputSize],
        DType.float32
      );

      // Post-process the result to get the class label
      if (_labels != null) {
        // The output is a list of scores (logits). Find the index of the highest score.
        int maxIndex = 0;
        double maxValue = double.negativeInfinity;
        for (int i = 0; i < prediction!.length; i++) {
          if (prediction[i] > maxValue) {
            maxValue = prediction[i];
            maxIndex = i;
          }
        }
        final predictedLabel = _labels![maxIndex];
        
        // Show the result in the modal
        _showObjectDetectionModal(predictedLabel);
      }
    } catch (e) {
      debugPrint('Error during inference: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isInferencing = false);
    }
  }

  /// Converts the captured image into a normalized tensor for the model.
  Future<List<double>> _preprocessImage(XFile imageFile) async {
    final bytes = await File(imageFile.path).readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Could not decode image from path: ${imageFile.path}');
    }

    // Resize the image to the model's input size (224x224)
    img.Image resizedImage =
        img.copyResize(originalImage, width: _inputSize, height: _inputSize);

    // Convert the image to a Float32List of normalized pixel values.
    // This process must exactly match the transformations in your Python script.
    // The model expects a flat list of pixels in [RRR...GGG...BBB...] format.
    Float32List imageAsList = Float32List(1 * 3 * _inputSize * _inputSize);
    int bufferIndex = 0;

    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // Normalize and populate the list in R, G, B order
        // 1. Convert pixel from 0-255 to 0.0-1.0 (like ToTensor())
        // 2. Apply normalization: (value - mean) / std
        imageAsList[bufferIndex] = ((pixel.r / 255.0) - _means[0]) / _stds[0];
        imageAsList[bufferIndex + (_inputSize * _inputSize)] =
            ((pixel.g / 255.0) - _means[1]) / _stds[1];
        imageAsList[bufferIndex + (2 * _inputSize * _inputSize)] =
            ((pixel.b / 255.0) - _means[2]) / _stds[2];
        bufferIndex++;
      }
    }

    return imageAsList.toList();
  }

  /// Shows the bottom modal sheet with the detected object's information.
  void _showObjectDetectionModal(String objectName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ObjectDetectionModal(
        objectName: objectName, // Use the dynamic prediction result
        category: 'Identified Object', // This can be made dynamic later
        gradeLevel: 'Grade 1 & 2',
        foundCount: 8, // This can be made dynamic later
        learningTip: 'Ask Joy to find other objects like the $objectName!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled =
        _isModelLoading || !_isCameraInitialized || _isInferencing;

    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer for centering
                  const Text(
                    'Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search, color: Colors.white),
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
                  alignment: Alignment.center,
                  children: [
                    // Camera preview or placeholder
                    if (_isCameraInitialized && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),

                    // Instruction bubble
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
                        child: Text(
                          _isModelLoading
                              ? 'Loading model...'
                              : 'Point at an object!',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Target reticle
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.25,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        // Reticle crosshairs can be added here if needed
                      ),
                    ),

                    // Capture Button
                    Positioned(
                      bottom: 40,
                      child: GestureDetector(
                        onTap: isButtonDisabled ? null : _captureAndInfer,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isButtonDisabled ? Colors.grey : Colors.white,
                            border: Border.all(color: primaryColor, width: 4),
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
                                    color: primaryColor)
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: const BoxDecoration(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? primaryColor : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../utils/colors.dart';
// import '../widgets/object_detection_modal.dart';

// class ScanScreen extends StatefulWidget {
//   const ScanScreen({super.key});

//   @override
//   State<ScanScreen> createState() => _ScanScreenState();
// }

// class _ScanScreenState extends State<ScanScreen> {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isCameraInitialized = false;
//   int _currentIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   Future<void> _initializeCamera() async {
//     // Request camera permission
//     final status = await Permission.camera.request();
//     if (status != PermissionStatus.granted) {
//       return;
//     }

//     // Get available cameras
//     _cameras = await availableCameras();
//     if (_cameras == null || _cameras!.isEmpty) {
//       return;
//     }

//     // Initialize camera controller
//     _cameraController = CameraController(
//       _cameras![0],
//       ResolutionPreset.high,
//       enableAudio: false,
//     );

//     try {
//       await _cameraController!.initialize();
//       if (mounted) {
//         setState(() {
//           _isCameraInitialized = true;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error initializing camera: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   void _onTabTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
    
//     // Navigate to different screens based on tab selection
//     switch (index) {
//       case 0:
//         // Already on scan screen
//         break;
//       case 1:
//         Navigator.pushNamed(context, '/history');
//         break;
//       case 2:
//         Navigator.pushNamed(context, '/settings');
//         break;
//     }
//   }

//   Future<void> _captureImage() async {
//     try {
//       // Capture image using camera
//       final XFile? image = await _cameraController?.takePicture();
      
//       if (image != null) {
//         // Simulate object detection with mock data
//         _showObjectDetectionModal();
//       }
//     } catch (e) {
//       debugPrint('Error capturing image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to capture image. Please try again.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _showObjectDetectionModal() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => const ObjectDetectionModal(
//         objectName: 'Spoon',
//         category: 'Kitchen Items',
//         gradeLevel: 'Grade 1 & 2',
//         foundCount: 8,
//         learningTip: 'Ask Joy to find other objects used for eating!',
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF2A2A2A), // Dark gray background
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top navigation bar
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const SizedBox(width: 24), // Spacer for centering
//                   const Text(
//                     'Scan',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () {
//                       // Search functionality
//                     },
//                     icon: const Icon(
//                       Icons.search,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             // Main content area
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 color: const Color(0xFF3A3A3A), // Slightly lighter gray for camera view
//                 child: Stack(
//                   children: [
//                     // Camera preview or placeholder
//                     if (_isCameraInitialized && _cameraController != null)
//                       CameraPreview(_cameraController!)
//                     else
//                       Container(
//                         width: double.infinity,
//                         height: double.infinity,
//                         color: const Color(0xFF3A3A3A),
//                         child: const Center(
//                           child: Icon(
//                             Icons.camera_alt,
//                             size: 64,
//                             color: Color(0xFF6A6A6A),
//                           ),
//                         ),
//                       ),
                    
//                     // Instruction bubble
//                     Positioned(
//                       top: MediaQuery.of(context).size.height * 0.25,
//                       left: 0,
//                       right: 0,
//                       child: Center(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 12,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: const Text(
//                             'Point at an object!',
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
                    
//                     // Target reticle
//                     Positioned(
//                       top: MediaQuery.of(context).size.height * 0.35,
//                       left: 0,
//                       right: 0,
//                       child: Center(
//                         child: Container(
//                           width: 120,
//                           height: 120,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: Colors.white,
//                               width: 2,
//                             ),
//                           ),
//                           child: Stack(
//                             children: [
//                               // Placeholder icon
//                               const Center(
//                                 child: Icon(
//                                   Icons.landscape,
//                                   size: 40,
//                                   color: Color(0xFF6A6A6A),
//                                 ),
//                               ),
//                               // Crosshair
//                               Center(
//                                 child: Container(
//                                   width: 2,
//                                   height: 2,
//                                   decoration: const BoxDecoration(
//                                     color: Colors.white,
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                               // Horizontal line
//                               Center(
//                                 child: Container(
//                                   width: 30,
//                                   height: 2,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               // Vertical line
//                               Center(
//                                 child: Container(
//                                   width: 2,
//                                   height: 30,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
                    
//                     // Capture Button
//                     Positioned(
//                       bottom: MediaQuery.of(context).size.height * 0.15,
//                       left: 0,
//                       right: 0,
//                       child: Center(
//                         child: GestureDetector(
//                           onTap: _captureImage,
//                           child: Container(
//                             width: 80,
//                             height: 80,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Colors.white,
//                               border: Border.all(
//                                 color: primaryColor,
//                                 width: 4,
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.3),
//                                   blurRadius: 10,
//                                   offset: const Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: Center(
//                               child: Container(
//                                 width: 60,
//                                 height: 60,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: primaryColor,
//                                 ),
//                                 child: const Icon(
//                                   Icons.camera_alt,
//                                   color: Colors.white,
//                                   size: 32,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Container(
//         height: 80,
//         decoration: const BoxDecoration(
//           color: Color(0xFF1A1A1A),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildNavItem(
//               icon: Icons.camera_alt,
//               label: 'Scan',
//               isActive: _currentIndex == 0,
//               onTap: () => _onTabTapped(0),
//             ),
//             _buildNavItem(
//               icon: Icons.history,
//               label: 'History',
//               isActive: _currentIndex == 1,
//               onTap: () => _onTabTapped(1),
//             ),
//             _buildNavItem(
//               icon: Icons.settings,
//               label: 'Settings',
//               isActive: _currentIndex == 2,
//               onTap: () => _onTabTapped(2),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem({
//     required IconData icon,
//     required String label,
//     required bool isActive,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: isActive ? primaryColor : Colors.white,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isActive ? primaryColor : Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
