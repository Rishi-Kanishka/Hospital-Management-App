import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../scan/direct_scanner.dart';
import 'package:readit/screens/emr_records_screen.dart';
import 'package:readit/services/firebase_service.dart';
import 'package:readit/view/auth/login_page.dart';
import 'package:readit/widget/user_profile_card.dart';
import 'package:readit/view/home/flat_action_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1F3C88);
    const accentBlue = Color(0xFF3659B5);
    const lightGray = Color(0xFFF5F5F5);
    // Removed unused flatCardColor, flatIconColor, flatTextColor

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 20.0), // Increased left padding
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'RxCapture',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontSize: 22,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await FirebaseService().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: \\${e.toString()}')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const UserProfileCard(),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: accentBlue,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      child: FlatActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DirectScanner(source: ImageSource.camera),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      child: FlatActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DirectScanner(
                                source: ImageSource.gallery),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      child: FlatActionButton(
                        icon: Icons.folder_open,
                        label: 'EMR Records',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EMRRecordsScreen()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      child: FlatActionButton(
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: lightGray,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (context) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded,
                                          color: Color(0xFF1F3C88), size: 28),
                                      const SizedBox(width: 12),
                                      Text(
                                        'About RxCapture',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F3C88),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'RxCapture is a modern EMR and prescription management app for doctors. Effortlessly scan, store, and manage patient records with a professional, secure, and user-friendly interface.',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Icon(Icons.verified,
                                          color: Colors.green, size: 20),
                                      SizedBox(width: 8),
                                      Text('Version 1.0.0',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.copyright,
                                          size: 18, color: Colors.black38),
                                      SizedBox(width: 8),
                                      Text('2025 RxCapture Team',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black38)),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close',
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  '© 2025 RxCapture. All rights reserved.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: Colors.black38,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
