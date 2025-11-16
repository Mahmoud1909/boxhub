// lib/services/firestore_service.dart
// Small Firestore helper for BoxHub with robust logging and helpful hints for common errors.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  /// Save user data into /users/{uid} with server timestamps.
  /// Returns true on success, false otherwise.
  Future<bool> saveUserData(String uid, Map<String, dynamic> data,
      {Duration timeout = const Duration(seconds: 8)}) async {
    final docRef = _usersRef.doc(uid);
    debugPrint('➡️ [BoxHub][FS] saveUserData() start for uid=$uid');

    if (uid.trim().isEmpty) {
      debugPrint('❌ [BoxHub][FS] Provided uid is empty — aborting save.');
      return false;
    }

    try {
      debugPrint('ℹ️ [BoxHub][FS] Checking existing document for uid=$uid');
      final snapshot = await docRef.get().timeout(timeout);
      final exists = snapshot.exists;
      debugPrint('ℹ️ [BoxHub][FS] Document exists: $exists');

      final payload = <String, dynamic>{}..addAll(data);
      if (!exists) payload['createdAt'] = FieldValue.serverTimestamp();
      payload['updatedAt'] = FieldValue.serverTimestamp();

      debugPrint('ℹ️ [BoxHub][FS] Writing keys=${payload.keys.toList()} to users/$uid ...');
      await docRef.set(payload, SetOptions(merge: true)).timeout(timeout);
      debugPrint('✅ [BoxHub][FS] saveUserData success for uid=$uid');
      return true;
    } on FirebaseException catch (fe) {
      debugPrint('❌ [BoxHub][FS] FirebaseException saving uid=$uid -> code=${fe.code} message=${fe.message}');
      if (fe.code == 'permission-denied') {
        debugPrint('👉 [BoxHub][FS] permission-denied: your Firestore rules disallow this write.');
        debugPrint('👉 [BoxHub][FS] ACTION: In Firebase Console → Firestore → Rules, allow authenticated user write to /users/{userId} or use a safe test rule temporarily.');
        debugPrint(r'''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}''');
      } else if (fe.code == 'not-found') {
        debugPrint('👉 [BoxHub][FS] not-found: Firestore default database may not be created; open console to create it.');
      } else if (fe.code == 'unauthenticated') {
        debugPrint('👉 [BoxHub][FS] unauthenticated: client is not authenticated; ensure user is signed in.');
      } else if (fe.code == 'unavailable' || fe.code == 'deadline-exceeded') {
        debugPrint('👉 [BoxHub][FS] backend unavailable or request timed out. Check network and Firebase status.');
      }
      return false;
    } on TimeoutException catch (te) {
      debugPrint('❌ [BoxHub][FS] TimeoutException while saving uid=$uid -> $te');
      return false;
    } catch (e, st) {
      debugPrint('❌ [BoxHub][FS] Unknown error saving uid=$uid -> $e');
      debugPrint(st.toString());
      return false;
    }
  }

  /// Convenience: write to a fixed fallback doc id (useful if primary writes fail).
  Future<bool> saveToFixedUserDoc(Map<String, dynamic> data, {Duration timeout = const Duration(seconds: 8)}) {
    const fixedUid = 'SF9d8UzdjoEATMsN923O';
    debugPrint('➡️ [BoxHub][FS] saveToFixedUserDoc() -> users/$fixedUid');
    return saveUserData(fixedUid, data, timeout: timeout);
  }

  /// Read single user document.
  Future<Map<String, dynamic>?> getUserData(String uid, {Duration timeout = const Duration(seconds: 6)}) async {
    final docRef = _usersRef.doc(uid);
    debugPrint('➡️ [BoxHub][FS] getUserData() uid=$uid');
    try {
      final snap = await docRef.get().timeout(timeout);
      if (!snap.exists) {
        debugPrint('ℹ️ [BoxHub][FS] getUserData: document not found uid=$uid');
        return null;
      }
      final data = snap.data() as Map<String, dynamic>;
      debugPrint('✅ [BoxHub][FS] getUserData success keys=${data.keys.toList()}');
      return data;
    } catch (e, st) {
      debugPrint('❌ [BoxHub][FS] getUserData error for uid=$uid -> $e');
      debugPrint(st.toString());
      return null;
    }
  }
}
