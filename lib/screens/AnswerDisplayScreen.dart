import 'package:flutter/material.dart';

class AnswerDisplayScreen extends StatelessWidget {
  final String query;
  final String answer;

  const AnswerDisplayScreen({super.key, required this.query, required this.answer});

  void _submit() {
    print("Back button pressed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the body background to white
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: const Color(0xFF0b3c66),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
          children: [
            // Styled text positioned above the card
            Padding(
              padding: const EdgeInsets.only(top: 48.0, bottom: 18.0), // Padding for top and bottom
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF0b3c66), Color(0xFF0b3c66)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  "Response To Your Query:",
                  style: TextStyle(
                    fontSize: 18, // Updated font size for professionalism
                    fontWeight: FontWeight.bold, // Bold text for emphasis
                    letterSpacing: 1.5, // Slight letter spacing
                    color: Colors.white, // Placeholder, overridden by shader
                  ),
                  textAlign: TextAlign.left, // Align text to the left
                ),
              ),
            ),

            // Main card displaying the query and answer
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE), // Subtle blue background for card
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF0b3c66),
                          child: Icon(
                            Icons.question_answer,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            query, // Dynamically display the query
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black26),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      answer, // Dynamically display the answer
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 46), // Spacing between text and button

                  // Back Button inside the card
                  Center(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0b3c66),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text('Back'),
                    ),
                  ),
                  const SizedBox(height: 20), // Padding after the button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
