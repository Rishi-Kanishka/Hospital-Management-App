import 'package:flutter/material.dart';
import 'emr_records_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadIt Home',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F3C88),
        elevation: 2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                  backgroundColor: Colors.blue[50],
                  shadowColor: Colors.black12,
                ),
                icon: const Icon(Icons.folder_open,
                    color: Color(0xFF1F3C88), size: 32),
                label: const Text(
                  'EMR Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F3C88),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EMRRecordsScreen()),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Add other home screen content here
            ],
          ),
        ),
      ),
    );
  }
}
