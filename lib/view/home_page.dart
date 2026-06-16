import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              // Navigate to the history page
              Navigator.pushNamed(context, '/history');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Style for the history button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('History'),
          ),
          const SizedBox(
              height: 16), // Add spacing between History and Logout buttons
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Sign out the user
              Navigator.pushReplacementNamed(
                  context, '/login'); // Navigate back to login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Same style as the other buttons
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
