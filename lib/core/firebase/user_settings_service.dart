import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingsService {
  UserSettingsService._();

  static final instance = UserSettingsService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(_uid);

  // 🔔 RAPPELS

  Future<void> setReminderEnabled(bool value) async {
    await _userDoc.set({'reminderEnabled': value}, SetOptions(merge: true));
  }

  Future<bool> getReminderEnabled() async {
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['reminderEnabled'] ?? false;
  }

  Future<void> setReminderTime(String time) async {
    await _userDoc.set({'reminderTime': time}, SetOptions(merge: true));
  }

  Future<String> getReminderTime() async {
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['reminderTime'] ?? '21:00';
  }

  // ⚠️ ALERTES BUDGET

  Future<void> setBudgetAlertEnabled(bool value) async {
    await _userDoc.set({'budgetAlertEnabled': value}, SetOptions(merge: true));
  }

  Future<bool> getBudgetAlertEnabled() async {
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['budgetAlertEnabled'] ?? true;
  }

  Future<void> setBudgetAlertThreshold(int value) async {
    await _userDoc.set({'budgetThreshold': value}, SetOptions(merge: true));
  }

  Future<int> getBudgetAlertThreshold() async {
    final doc = await _userDoc.get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['budgetThreshold'] ?? 80;
  }
}