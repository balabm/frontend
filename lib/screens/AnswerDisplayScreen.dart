import 'package:flutter/material.dart';

class AnswerDisplayScreen extends StatelessWidget {
  final String query;
  final String answer;

  AnswerDisplayScreen({required this.query, required this.answer});

  void _submit() {
    print("Back button pressed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the body background to white
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Color.fromRGBO(16, 121, 63,1 ),
        iconTheme: IconThemeData(color: Colors.white),
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
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Color.fromRGBO(16, 121, 63,1 ), Color.fromRGBO(16, 121, 63,1 )],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
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
                color: Color(0xFFE8F0FE), // Subtle blue background for card
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
                        CircleAvatar(
                          backgroundColor: Color.fromRGBO(16, 121, 63,1 ),
                          child: Icon(
                            Icons.question_answer,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            query, // Dynamically display the query
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.black26),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      answer, // Dynamically display the answer
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: 46), // Spacing between text and button

                  // Back Button inside the card
                  Center(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text('Back'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color.fromRGBO(16, 121, 63,1 ),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // Padding after the button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
