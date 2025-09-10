import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';

class VerifyAccountScreen extends StatelessWidget {
  const VerifyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CBSee',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: secondaryColor),
                ),
                const SizedBox(height: 30),
                const Icon(Icons.lock_open_outlined, size: 60, color: primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'Verify Your Account',
                  style: TextStyle(fontSize: 24, color: secondaryColor),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please enter the 6-digit code sent to your email or phone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      child: TextField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Resend Code', style: TextStyle(color: primaryColor)),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Verify',
                  onPressed: () {
                    // Add verification logic
                  },
                  color: const Color(0xFF00E676),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}