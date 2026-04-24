import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../auth/data/models/user_model.dart';
import '../../models/transaction_model.dart';
import 'sandokti_firestore.dart';

class BudgetFirestoreDatasource {
  BudgetFirestoreDatasource({
    SandoktiFirestore? store,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _store = store ?? SandoktiFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final SandoktiFirestore _store;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> _ensureReady() async {
    await _store.ensureInitialized();
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _userCollection(
    String uid,
    String name,
  ) =>
      _userDoc(uid).collection(name);

  Future<String> _requireCurrentUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    return user.uid;
  }

  Never _throwFriendly(Object error) {
    if (error is FirebaseAuthException) {
      throw Exception(_mapAuthError(error));
    }
    if (error is FirebaseException) {
      throw Exception(_mapFirestoreError(error));
    }
    if (error is SocketException) {
      throw Exception('Aucune connexion Internet. Vérifie ton réseau.');
    }
    if (error is TimeoutException) {
      throw Exception('La requête a pris trop de temps. Réessaie.');
    }
    throw Exception('Une erreur inattendue est survenue : $error');
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email ou mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email existe déjà';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'network-request-failed':
        return 'Aucune connexion Internet. Vérifie ton réseau.';
      case 'requires-recent-login':
        return 'Reconnecte-toi puis réessaie cette opération.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      default:
        return e.message ?? "Erreur d'authentification";
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'Service indisponible. Vérifie ta connexion Internet.';
      case 'permission-denied':
        return 'Accès refusé aux données.';
      case 'not-found':
        return 'Donnée introuvable.';
      case 'deadline-exceeded':
        return 'La requête a expiré. Réessaie.';
      default:
        return e.message ?? 'Erreur Firestore';
    }
  }

  int _timestampToMillis(dynamic value) {
    if (value == null) return 0;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Timestamp _millisToTimestamp(int millis) {
    return Timestamp.fromMillisecondsSinceEpoch(millis);
  }

  String _monthsToRaw(List<int>? months) {
    if (months == null || months.isEmpty) return '';
    final sorted = [...months]..sort();
    return sorted.join(',');
  }

  List<int> _rawToMonths(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList()
      ..sort();
  }

  Map<String, dynamic> _docData(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return {
      'id': doc.id,
      ...?doc.data(),
    };
  }

  Future<Map<String, Map<String, dynamic>>> _categoriesMap() async {
    final snapshot = await _firestore.collection('categories').get();

    return {
      for (final doc in snapshot.docs) doc.id: _docData(doc),
    };
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _queryRange({
    required CollectionReference<Map<String, dynamic>> collection,
    required String field,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await collection
        .where(field, isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where(field, isLessThan: Timestamp.fromDate(end))
        .get();

    return snapshot.docs;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    await _ensureReady();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = _docData(snapshot.docs.first);
      return UserModel.fromMap({
        'id': snapshot.docs.first.id,
        'fullName': data['fullName'] ?? '',
        'email': data['email'] ?? '',
        'monthlySalaryCents': data['monthlySalaryCents'] ?? 0,
        'householdType': data['householdType'] ?? 'single',
        'childrenCount': data['childrenCount'] ?? 0,
        'createdAt': _timestampToMillis(data['createdAt']),
      });
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> setCurrentUserId(String userId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    if (currentUid != userId) {
      throw Exception('La session Firebase ne correspond pas à cet utilisateur');
    }
  }

  Future<UserModel> registerLocalUserOnly({
    required String fullName,
    required String email,
    required int monthlySalaryDh,
    required String householdType,
    required int childrenCount,
    String? externalAuthId,
  }) async {
    await _ensureReady();

    try {
      final uid = externalAuthId ?? await _requireCurrentUserId();
      final now = DateTime.now();

      await _userDoc(uid).set({
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'monthlySalaryCents': monthlySalaryDh * 100,
        'householdType': householdType,
        'childrenCount': childrenCount,
        'createdAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      return UserModel(
        id: uid,
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        monthlySalaryCents: monthlySalaryDh * 100,
        householdType: householdType,
        childrenCount: childrenCount,
        createdAt: now.millisecondsSinceEpoch,
      );
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> updateMonthlySalary({
    required int monthlySalaryDh,
  }) async {
    await _ensureReady();

    if (monthlySalaryDh <= 0) {
      throw Exception('Le salaire mensuel doit être supérieur à 0');
    }

    try {
      final uid = await _requireCurrentUserId();
      await _userDoc(uid).set({
        'monthlySalaryCents': monthlySalaryDh * 100,
      }, SetOptions(merge: true));
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<String?> getSetting(String key) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final doc = await _userCollection(uid, 'settings').doc(key).get();

      if (!doc.exists) return null;
      return doc.data()?['value']?.toString();
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> setSetting(String key, String value) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      await _userCollection(uid, 'settings').doc(key).set({
        'value': value,
      }, SetOptions(merge: true));
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<UserModel?> getCurrentUser() async {
    await _ensureReady();

    try {
      final current = _auth.currentUser;
      if (current == null) return null;

      final doc = await _userDoc(current.uid).get();
      if (!doc.exists) return null;

      final data = doc.data() ?? <String, dynamic>{};

      return UserModel(
        id: current.uid,
        fullName: (data['fullName'] as String?) ?? '',
        email: (data['email'] as String?) ?? (current.email ?? ''),
        monthlySalaryCents: (data['monthlySalaryCents'] as int?) ?? 0,
        householdType: (data['householdType'] as String?) ?? 'single',
        childrenCount: (data['childrenCount'] as int?) ?? 0,
        createdAt: _timestampToMillis(data['createdAt']),
      );
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Utilisateur introuvable après connexion');
      }

      return user;
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
  }) async {
    await _ensureReady();

    final cleanName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw Exception('Le nom est obligatoire');
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Email invalide');
    }

    try {
      final uid = await _requireCurrentUserId();
      final current = _auth.currentUser!;

      final existing = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
        throw Exception('Cet email est déjà utilisé');
      }

       if ((current.email ?? '') != cleanEmail) {
  throw Exception(
    "Le changement d'email nécessite une reconnexion. Garde le même email pour le moment.",
  );
}
      if ((current.displayName ?? '') != cleanName) {
        await current.updateDisplayName(cleanName);
      }

      await _userDoc(uid).set({
        'fullName': cleanName,
        'email': cleanEmail,
      }, SetOptions(merge: true));
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<UserModel> registerUser({
    required String fullName,
    required String email,
    required String password,
    required int monthlySalaryDh,
    required String householdType,
    required int childrenCount,
  }) async {
    await _ensureReady();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Impossible de créer le compte');
      }

      await user.updateDisplayName(fullName.trim());

      final now = DateTime.now();

      await _userDoc(user.uid).set({
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'monthlySalaryCents': monthlySalaryDh * 100,
        'householdType': householdType,
        'childrenCount': childrenCount,
        'createdAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      return UserModel(
        id: user.uid,
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        monthlySalaryCents: monthlySalaryDh * 100,
        householdType: householdType,
        childrenCount: childrenCount,
        createdAt: now.millisecondsSinceEpoch,
      );
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty || !clean.contains('@')) {
      throw Exception('Adresse email invalide');
    }
    try {
      await _auth.sendPasswordResetEmail(email: clean);
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _ensureReady();

    if (newPassword.trim().length < 6) {
      throw Exception(
        'Le nouveau mot de passe doit contenir au moins 6 caractères',
      );
    }

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Utilisateur introuvable');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword.trim());
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<void> resetCurrentUserData() async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();

      await _deleteCollection(_userCollection(uid, 'transactions'));
      await _deleteCollection(_userCollection(uid, 'incomes'));
      await _deleteCollection(_userCollection(uid, 'savings'));
      await _deleteCollection(_userCollection(uid, 'planned_expenses'));
      await _deleteCollection(_userCollection(uid, 'fixed_expenses'));
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final batchSnapshot = await collection.limit(100).get();
      if (batchSnapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in batchSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<bool> getExpenseReminderEnabled() async {
    final value = await getSetting('expense_reminder_enabled');
    return value == '1';
  }

  Future<void> setExpenseReminderEnabled(bool enabled) async {
    await setSetting('expense_reminder_enabled', enabled ? '1' : '0');
  }

  Future<String> getExpenseReminderTime() async {
    final value = await getSetting('expense_reminder_time');
    if (value == null || value.isEmpty) return '21:00';
    return value;
  }

  Future<void> setExpenseReminderTime(String hhmm) async {
    await setSetting('expense_reminder_time', hhmm);
  }

  Future<void> insertTransaction(TransactionModel tx) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final docId = tx.id.isEmpty
          ? _userCollection(uid, 'transactions').doc().id
          : tx.id;

      await _userCollection(uid, 'transactions').doc(docId).set({
        'type': tx.type,
        'title': tx.title,
        'amountCents': tx.amountCents,
        'categoryId': tx.categoryId,
        'occurredAt': _millisToTimestamp(tx.occurredAt),
      }, SetOptions(merge: true));
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 8}) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final categories = await _categoriesMap();

      final expenseSnap = await _userCollection(uid, 'transactions')
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      final incomeSnap = await _userCollection(uid, 'incomes')
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      final savingSnap = await _userCollection(uid, 'savings')
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .get();

      final allRows = <Map<String, Object?>>[];

      for (final doc in expenseSnap.docs) {
        final data = doc.data();
        final catId = data['categoryId'] as String?;
        final cat = catId == null ? null : categories[catId];

        allRows.add({
          'id': doc.id,
          'type': data['type'] ?? 'expense',
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'categoryId': catId,
          'occurredAt': _timestampToMillis(data['occurredAt']),
          'userId': uid,
          'categoryName': cat?['name'],
          'categoryIconKey': cat?['iconKey'],
          'categoryColorHex': cat?['colorHex'],
        });
      }

      for (final doc in incomeSnap.docs) {
        final data = doc.data();
        allRows.add({
          'id': doc.id,
          'type': 'income',
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'categoryId': null,
          'occurredAt': _timestampToMillis(data['occurredAt']),
          'userId': uid,
          'categoryName': data['type'] ?? 'Revenu',
          'categoryIconKey': 'safe',
          'categoryColorHex': '0xFFD4AF37',
        });
      }

      for (final doc in savingSnap.docs) {
        final data = doc.data();
        allRows.add({
          'id': doc.id,
          'type': 'saving',
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'categoryId': 'cat_saving',
          'occurredAt': _timestampToMillis(data['occurredAt']),
          'userId': uid,
          'categoryName': 'Épargne',
          'categoryIconKey': 'safe',
          'categoryColorHex': '0xFF1E3A8A',
        });
      }

      allRows.sort((a, b) {
        final aTime = (a['occurredAt'] as int?) ?? 0;
        final bTime = (b['occurredAt'] as int?) ?? 0;
        return bTime.compareTo(aTime);
      });

      return allRows.take(limit).map(TransactionModel.fromMap).toList();
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<List<TransactionModel>> getTransactionsForMonth(
    int year,
    int month,
  ) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final categories = await _categoriesMap();

      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final expenseDocs = await _queryRange(
        collection: _userCollection(uid, 'transactions'),
        field: 'occurredAt',
        start: start,
        end: end,
      );

      final incomeDocs = await _queryRange(
        collection: _userCollection(uid, 'incomes'),
        field: 'occurredAt',
        start: start,
        end: end,
      );

      final savingDocs = await _queryRange(
        collection: _userCollection(uid, 'savings'),
        field: 'occurredAt',
        start: start,
        end: end,
      );

      final allRows = <Map<String, Object?>>[];

      for (final doc in expenseDocs) {
        final data = doc.data();
        final catId = data['categoryId'] as String?;
        final cat = catId == null ? null : categories[catId];

        allRows.add({
          'id': doc.id,
          'type': data['type'] ?? 'expense',
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'categoryId': catId,
          'occurredAt': _timestampToMillis(data['occurredAt']),
          'userId': uid,
          'categoryName': cat?['name'],
          'categoryIconKey': cat?['iconKey'],
          'categoryColorHex': cat?['colorHex'],
        });
      }

      for (final doc in incomeDocs) {
        final data = doc.data();
        allRows.add({
          'id': doc.id,
          'type': 'income',
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'categoryId': null,
          'occurredAt': _timestampToMillis(data['occurredAt']),
          'userId': uid,
          'categoryName': data['type'] ?? 'Revenu',
          'categoryIconKey': 'safe',
          'categoryColorHex': '0xFFD4AF37',
        });
      }

      for (final doc in savingDocs) {
        final data = doc.data();
        allRows.add({
          'id': doc.id,
          'type': 'saving',
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'categoryId': 'cat_saving',
          'occurredAt': _timestampToMillis(data['occurredAt']),
          'userId': uid,
          'categoryName': 'Épargne',
          'categoryIconKey': 'safe',
          'categoryColorHex': '0xFF1E3A8A',
        });
      }

      allRows.sort((a, b) {
        final aTime = (a['occurredAt'] as int?) ?? 0;
        final bTime = (b['occurredAt'] as int?) ?? 0;
        return bTime.compareTo(aTime);
      });

      return allRows.map(TransactionModel.fromMap).toList();
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<int> getMonthlyExpenseCents(int year, int month) async {
    final txs = await getTransactionsForMonth(year, month);
    return txs
        .where((e) => e.type == 'expense')
        .fold<int>(0, (sum, e) => sum + e.amountCents.toInt());
  }

  Future<List<Map<String, Object?>>> getMonthlyExpenseByCategoryRaw(
    int year,
    int month,
  ) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final categoriesSnap = await _firestore.collection('categories').get();
      final expensesSnap = await _userCollection(uid, 'transactions')
          .where('type', isEqualTo: 'expense')
          .where('occurredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('occurredAt', isLessThan: Timestamp.fromDate(end))
          .get();

      final totals = <String, int>{};

      for (final tx in expensesSnap.docs) {
        final data = tx.data();
        final categoryId = data['categoryId'] as String?;
        if (categoryId == null || categoryId.isEmpty) continue;
        final amount = (data['amountCents'] as int?) ?? 0;
        totals[categoryId] = (totals[categoryId] ?? 0) + amount;
      }

      final rows = categoriesSnap.docs.map((doc) {
        final data = doc.data();
        return <String, Object?>{
          'categoryId': doc.id,
          'name': data['name'] ?? '',
          'totalCents': totals[doc.id] ?? 0,
        };
      }).toList();

      rows.sort((a, b) {
        final aTotal = (a['totalCents'] as int?) ?? 0;
        final bTotal = (b['totalCents'] as int?) ?? 0;
        return bTotal.compareTo(aTotal);
      });

      return rows;
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> insertIncome({
    required String title,
    required int amountDh,
    required String type,
  }) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final now = DateTime.now();

      final doc = _userCollection(uid, 'incomes').doc();
      await doc.set({
        'title': title,
        'amountCents': amountDh * 100,
        'type': type,
        'occurredAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<int> getMonthlyIncomeFixedCents() async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      return currentUser.monthlySalaryCents;
    }

    final v = await getSetting('monthly_income_cents');
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<int> getMonthlyIncomeTotalCents(int year, int month) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final fixed = await getMonthlyIncomeFixedCents();

      final docs = await _queryRange(
        collection: _userCollection(uid, 'incomes'),
        field: 'occurredAt',
        start: start,
        end: end,
      );

      final extra = docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['amountCents'] as int?) ?? 0),
      );

      return fixed + extra;
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<List<Map<String, Object?>>> getFixedExpenses() async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final snapshot = await _userCollection(uid, 'fixed_expenses')
          .orderBy('title')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return <String, Object?>{
          'id': doc.id,
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'userId': uid,
          'chargeType': data['chargeType'] ?? 'monthly',
          'activeMonths': _monthsToRaw(
            (data['activeMonths'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList(),
          ),
          'createdAt': _timestampToMillis(data['createdAt']),
        };
      }).toList();
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> insertFixedExpense({
    required String title,
    required int amountDh,
    String chargeType = 'monthly',
    List<int>? activeMonths,
  }) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final doc = _userCollection(uid, 'fixed_expenses').doc();

      await doc.set({
        'title': title,
        'amountCents': amountDh * 100,
        'chargeType': chargeType,
        'activeMonths':
            chargeType == 'monthly' ? <int>[] : (activeMonths ?? <int>[]),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<void> updateFixedExpense({
    required String id,
    required String title,
    required int amountDh,
    String chargeType = 'monthly',
    List<int>? activeMonths,
  }) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();

      await _userCollection(uid, 'fixed_expenses').doc(id).set({
        'title': title,
        'amountCents': amountDh * 100,
        'chargeType': chargeType,
        'activeMonths':
            chargeType == 'monthly' ? <int>[] : (activeMonths ?? <int>[]),
      }, SetOptions(merge: true));
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<void> deleteFixedExpense(String id) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      await _userCollection(uid, 'fixed_expenses').doc(id).delete();
    } catch (e) {
      _throwFriendly(e);
    }
  }

  bool isFixedExpenseActiveForMonth(Map<String, Object?> item, int month) {
    final chargeType = (item['chargeType'] as String?) ?? 'monthly';

    if (chargeType == 'monthly') {
      return true;
    }

    final raw = item['activeMonths'] as String?;
    if (raw == null || raw.trim().isEmpty) {
      return false;
    }

    final months = _rawToMonths(raw);
    return months.contains(month);
  }

  Future<int> getTotalFixedExpensesCentsForMonth(int year, int month) async {
    final items = await getFixedExpenses();

    int total = 0;
    for (final item in items) {
      if (isFixedExpenseActiveForMonth(item, month)) {
        total += (item['amountCents'] as int?) ?? 0;
      }
    }

    return total;
  }

  Future<int> getTotalFixedExpensesCents() async {
    final now = DateTime.now();
    return getTotalFixedExpensesCentsForMonth(now.year, now.month);
  }

  Future<void> addPlannedExpense({
    required String title,
    required int totalDh,
    required DateTime targetDate,
  }) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final doc = _userCollection(uid, 'planned_expenses').doc();

      await doc.set({
        'title': title,
        'totalAmountCents': totalDh * 100,
        'targetDate': Timestamp.fromDate(targetDate),
      });
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<List<Map<String, Object?>>> getPlannedExpenses() async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final snapshot = await _userCollection(uid, 'planned_expenses')
          .orderBy('targetDate')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, Object?>{
          'id': doc.id,
          'title': data['title'] ?? '',
          'totalAmountCents': data['totalAmountCents'] ?? 0,
          'targetDate': _timestampToMillis(data['targetDate']),
          'userId': uid,
        };
      }).toList();
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<void> deletePlannedExpense(String id) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      await _userCollection(uid, 'planned_expenses').doc(id).delete();
    } catch (e) {
      _throwFriendly(e);
    }
  }

  int calculateMonthlySaving({
    required int totalCents,
    required int targetDateMillis,
  }) {
    final now = DateTime.now();
    final target = DateTime.fromMillisecondsSinceEpoch(targetDateMillis);

    int months = (target.year - now.year) * 12 + (target.month - now.month);
    if (months <= 0) months = 1;

    return (totalCents / months).round();
  }

  Future<void> addSaving({
    required String title,
    required int amountDh,
  }) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final now = DateTime.now();

      final doc = _userCollection(uid, 'savings').doc();
      await doc.set({
        'title': title,
        'amountCents': amountDh * 100,
        'occurredAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      _throwFriendly(e);
    }
  }

  Future<int> getMonthlySavingsCents(int year, int month) async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);

      final docs = await _queryRange(
        collection: _userCollection(uid, 'savings'),
        field: 'occurredAt',
        start: start,
        end: end,
      );

      return docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['amountCents'] as int?) ?? 0),
      );
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<int> getCumulativeSavingsCents() async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final snapshot = await _userCollection(uid, 'savings').get();

      return snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['amountCents'] as int?) ?? 0),
      );
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<List<Map<String, Object?>>> getSavingsHistory() async {
    await _ensureReady();

    try {
      final uid = await _requireCurrentUserId();
      final snapshot = await _userCollection(uid, 'savings')
          .orderBy('occurredAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, Object?>{
          'id': doc.id,
          'title': data['title'] ?? '',
          'amountCents': data['amountCents'] ?? 0,
          'userId': uid,
          'occurredAt': _timestampToMillis(data['occurredAt']),
        };
      }).toList();
    } catch (e) {
      return _throwFriendly(e);
    }
  }

  Future<List<Map<String, Object?>>> getMonthlySavingsHistory() async {
    final rows = await getSavingsHistory();

    final grouped = <String, int>{};

    for (final row in rows) {
      final occurredAt = (row['occurredAt'] as int?) ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(occurredAt);
      final year = date.year.toString().padLeft(4, '0');
      final month = date.month.toString().padLeft(2, '0');
      final key = '$year-$month';
      grouped[key] = (grouped[key] ?? 0) + ((row['amountCents'] as int?) ?? 0);
    }

    final keys = grouped.keys.toList()..sort();

    return keys.map((key) {
      final parts = key.split('-');
      return <String, Object?>{
        'year': parts[0],
        'month': parts[1],
        'totalCents': grouped[key] ?? 0,
      };
    }).toList();
  }
}