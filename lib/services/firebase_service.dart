import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  static Future<void> initialize() async {
    try {
      // Firebase.initializeApp() is now called in main.dart with options
      // This method is kept for additional initialization if needed
      Logger().i('Firebase service ready');
    } catch (e) {
      Logger().e('Error in Firebase service initialization: $e');
    }
  }

  // Save extracted text to Firestore
  Future<void> saveExtractedText(String text, String source) async {
    try {
      // Check if text is empty
      if (text.trim().isEmpty) {
        _logger.w('Empty text not saved to Firestore');
        return;
      }

      // Add a timeout to prevent hanging if Firestore is not responsive
      await _firestore.collection('extracted_texts').add({
        'text': text,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException(
            'Firestore operation timed out. Please check your Firebase setup.');
      });

      _logger.i('Text saved to Firestore successfully');
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('not been used in project')) {
        _logger.e(
            'Firebase permission error: Please enable Firestore in the Firebase Console');
      } else {
        _logger.e('Error saving text to Firestore: $e');
      }
      rethrow;
    }
  }

  // Get all extracted texts
  Future<List<Map<String, dynamic>>> getExtractedTexts() async {
    try {
      // Add a timeout to prevent hanging if Firestore is not responsive
      final snapshot = await _firestore
          .collection('extracted_texts')
          .orderBy('timestamp', descending: true)
          .get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException(
            'Firestore operation timed out. Please check your Firebase setup.');
      });

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'text': doc.data()['text'],
                'source': doc.data()['source'],
                'timestamp': doc.data()['timestamp'],
              })
          .toList();
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('not been used in project')) {
        _logger.e(
            'Firebase permission error: Please enable Firestore in the Firebase Console');
        return []; // Return empty list instead of throwing
      } else {
        _logger.e('Error getting extracted texts: $e');
        rethrow;
      }
    }
  }

  // Delete an extracted text
  Future<void> deleteExtractedText(String id) async {
    try {
      await _firestore.collection('extracted_texts').doc(id).delete();
      _logger.i('Text deleted from Firestore successfully');
    } catch (e) {
      _logger.e('Error deleting text from Firestore: $e');
      rethrow;
    }
  }

  // User signup
  Future<UserCredential?> signUp(
    String email,
    String password, {
    required String fullName,
    required String phoneNumber,
    required String medicalRegNumber,
    required String specialization,
    required int yearsOfExperience,
    required String hospitalName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'medicalRegNumber': medicalRegNumber,
        'specialization': specialization,
        'yearsOfExperience': yearsOfExperience,
        'hospitalName': hospitalName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      _logger.e('Error during sign up: $e');
      rethrow;
    }
  }

  // User login
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user profile exists
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        _logger.w('User profile not found in Firestore');
        // Create a basic profile if it doesn't exist
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _logger.i('User logged in successfully: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      _logger.e('Error during login: $e');
      rethrow;
    }
  }

  // User logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout: $e');
      rethrow;
    }
  }
}
