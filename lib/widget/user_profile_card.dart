import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class UserProfileCard extends StatelessWidget {
  static const Color primaryBlue = Color(0xFF1F3C88);
  static const Color lightBlue = Color(0xFFD6E4FF);
  static final Logger _logger = Logger();

  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _logger.w('No user is currently logged in');
      return const Center(
        child: Text('Please log in to view your profile'),
      );
    }

    _logger.i('Fetching profile for user: ${currentUser.uid}');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logger.e('Error fetching user data: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading profile: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        if (userData == null) {
          _logger.w('No user data found for ID: ${currentUser.uid}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profile data not found',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try logging out and signing in again',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        _logger.i('Successfully loaded user data');

        final fullName = userData['fullName'] as String? ?? 'N/A';
        final specialization = userData['specialization'] as String? ?? 'N/A';
        final hospitalName = userData['hospitalName'] as String? ?? 'N/A';
        final yearsOfExperience =
            userData['yearsOfExperience']?.toString() ?? 'N/A';
        final medicalRegNumber =
            userData['medicalRegNumber'] as String? ?? 'N/A';
        final phoneNumber = userData['phoneNumber'] as String? ?? 'N/A';

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8), // Reduced vertical gap
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFF5F5F5), // Match home screen background
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF5F5F5), // Match home screen background
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'D',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              specialization,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.local_hospital_outlined,
                          'Hospital/Clinic', hospitalName),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.timeline_outlined, 'Experience',
                          '$yearsOfExperience Years'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.badge_outlined, 'Registration No.',
                          medicalRegNumber),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          Icons.phone_outlined, 'Contact', phoneNumber),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
