import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Converted to a StatefulWidget
class ObjectDetectionModalWithTTS extends StatefulWidget {
  final FlutterTts flutterTts; // Pass the TTS instance
  final String objectName;
  final String category;
  final String gradeLevel;
  final int foundCount;
  final String learningTip;
  final String? imagePath;

  const ObjectDetectionModalWithTTS({
    super.key,
    required this.flutterTts,
    required this.objectName,
    required this.category,
    required this.gradeLevel,
    required this.foundCount,
    required this.learningTip,
    this.imagePath,
  });

  @override
  State<ObjectDetectionModalWithTTS> createState() =>
      _ObjectDetectionModalWithTTSState();
}

class _ObjectDetectionModalWithTTSState
    extends State<ObjectDetectionModalWithTTS> {
  // Manage speaking state locally
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    // Set up local listeners
    _setupTtsHandlers();
  }

  void _setupTtsHandlers() {
    widget.flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
    });

    widget.flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });

    widget.flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
      debugPrint('TTS Error from Modal: $msg');
    });
  }

  // Local replay function
  Future<void> _replayAudio() async {
    if (_isSpeaking) return;
    try {
      String textToSpeak =
          "I found a ${widget.objectName}. ${widget.learningTip}";
      await widget.flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('Error replaying audio: $e');
    }
  }

  @override
  void dispose() {
    // It's good practice to clear handlers to prevent memory leaks,
    // though in this case the TTS instance lives on in ScanScreen.
    widget.flutterTts.setStartHandler(() {});
    widget.flutterTts.setCompletionHandler(() {});
    widget.flutterTts.setErrorHandler((msg) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Object Image
                      Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5DC), // Light beige background
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: widget.imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  widget.imagePath!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.photo,
                                  size: 64,
                                  color: Color(0xFF6A6A6A),
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Object Name with Replay Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.objectName,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32), // Dark green
                              ),
                            ),
                          ),
                          // Replay Audio Button
                          Container(
                            decoration: BoxDecoration(
                              color: _isSpeaking
                                  ? const Color(0xFF2E7D32).withOpacity(0.1)
                                  : const Color(0xFFE8F5E8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isSpeaking
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF81C784),
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              // Use local state and function
                              onPressed: _isSpeaking ? null : _replayAudio,
                              icon: Icon(
                                _isSpeaking ? Icons.volume_up : Icons.replay,
                                color: const Color(0xFF2E7D32),
                                size: 28,
                              ),
                              tooltip:
                                  _isSpeaking ? 'Playing...' : 'Replay audio',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784), // Light green
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.category,
                          style: const TextStyle(
                            color: Color(0xFF2E7D32), // Dark green
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Grade Level
                      Text(
                        'Relevant for ${widget.gradeLevel}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Found Count
                      Text(
                        'Found by Joy ${widget.foundCount} times',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Actionable Tip
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFFE8F5E8), // Light green background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF81C784), // Light green border
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.eco, // Plant/sprout icon
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Learning Tip:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.learningTip,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF424242),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Add to favorites functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to favorites!'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side:
                                    const BorderSide(color: Color(0xFF2E7D32)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Add to Favorites',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Share functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Shared!'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Share',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}