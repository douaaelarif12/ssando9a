import 'package:cloud_firestore/cloud_firestore.dart';

class SandoktiFirestore {
  SandoktiFirestore._();

  static final SandoktiFirestore instance = SandoktiFirestore._();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get categories =>
      firestore.collection('categories');

  DocumentReference<Map<String, dynamic>> userDoc(String uid) {
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> userCollection(
    String uid,
    String name,
  ) {
    return userDoc(uid).collection(name);
  }

  Future<void> ensureInitialized() async {
    // Seed désactivé — les règles Firestore bloquent l'écriture côté client.
    // Les catégories sont lues depuis Firestore (déjà créées via Console).
  }
}