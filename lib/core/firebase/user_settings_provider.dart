import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserSettingsService {
  UserSettingsService._();

  static final UserSettingsService instance = UserSettingsService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    return _firestore.collection('users').doc(_uid);
  }

  // =========================
  // PROFIL : PHOTO
  // =========================

  Future<String> uploadProfileImage(File imageFile) async {
    final ref = _storage.ref().child('users/$_uid/profile/profile.jpg');

    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final photoUrl = await ref.getDownloadURL();

    await _userDoc.set(
      {
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return photoUrl;
  }

  Future<String?> getProfilePhotoUrl() async {
    final snapshot = await _userDoc.get();
    return snapshot.data()?['photoUrl'] as String?;
  }

  // =========================
  // RAPPELS
  // =========================

  Future<void> setReminderEnabled(bool value) async {
    await _userDoc.set(
      {
        'reminderEnabled': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> getReminderEnabled() async {
    final snapshot = await _userDoc.get();
    return snapshot.data()?['reminderEnabled'] as bool? ?? false;
  }

  Future<void> setReminderTime(String time) async {
    await _userDoc.set(
      {
        'reminderTime': time,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> getReminderTime() async {
    final snapshot = await _userDoc.get();
    return snapshot.data()?['reminderTime'] as String? ?? '21:00';
  }

  // =========================
  // ALERTES BUDGET
  // =========================

  Future<void> setBudgetAlertEnabled(bool value) async {
    await _userDoc.set(
      {
        'budgetAlertEnabled': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> getBudgetAlertEnabled() async {
    final snapshot = await _userDoc.get();
    return snapshot.data()?['budgetAlertEnabled'] as bool? ?? true;
  }

  Future<void> setBudgetAlertThreshold(int threshold) async {
    await _userDoc.set(
      {
        'budgetAlertThreshold': threshold,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<int> getBudgetAlertThreshold() async {
    final snapshot = await _userDoc.get();
    return snapshot.data()?['budgetAlertThreshold'] as int? ?? 80;
  }
}