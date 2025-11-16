// lib/services/user_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart'; // keep your UserProfile model here

class UserService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserService() {
    debugPrint('🔧 [BoxHub][UserService] Initialized (Firestore + Storage).');
    if (kDebugMode) debugPrint('🔎 Debug mode enabled - verbose logs active.');
  }

  String? get currentUid => _auth.currentUser?.uid;

  Map<String, DocumentReference<Map<String, dynamic>>> _docRefsForUid(String uid) {
    return {
      'users': _fs.collection('users').doc(uid),
      'usersL': _fs.collection('usersL').doc(uid),
    };
  }

  /// Normalize a Firestore document into a canonical map expected by UserProfile.fromMap
  Map<String, dynamic> _normalizeDocData(String docId, Map<String, dynamic> raw) {
    debugPrint('ℹ️ [BoxHub][UserService] Normalizing doc ($docId). Raw keys: ${raw.keys.toList()}');
    final r = Map<String, dynamic>.from(raw);
    final out = <String, dynamic>{};

    out['uid'] = (r['uid'] is String && (r['uid'] as String).trim().isNotEmpty) ? r['uid'] as String : docId;

    // name resolution
    String name = '';
    if (r['name'] is String && (r['name'] as String).trim().isNotEmpty) {
      name = (r['name'] as String).trim();
    } else if (r['displayName'] is String && (r['displayName'] as String).trim().isNotEmpty) {
      name = (r['displayName'] as String).trim();
    } else {
      final first = (r['first_name'] as String?)?.trim() ?? '';
      final last = (r['last_name'] as String?)?.trim() ?? '';
      if (first.isNotEmpty || last.isNotEmpty) name = (first + (last.isNotEmpty ? ' $last' : '')).trim();
    }
    out['name'] = name;

    // profile image candidates
    final profileCandidates = <String?>[
      (r['profileImageUrl'] as String?)?.trim(),
      (r['profile_image_url'] as String?)?.trim(),
      (r['photo_url'] as String?)?.trim(),
      (r['photoUrl'] as String?)?.trim(),
      (r['photo'] as String?)?.trim(),
    ];
    out['profileImageUrl'] = profileCandidates.firstWhere((c) => c != null && c.isNotEmpty, orElse: () => '') ?? '';

    // background / cover image
    final bgCandidates = <String?>[
      (r['backgroundImageUrl'] as String?)?.trim(),
      (r['background_image'] as String?)?.trim(),
      (r['background'] as String?)?.trim(),
    ];
    out['backgroundImageUrl'] = bgCandidates.firstWhere((c) => c != null && c.isNotEmpty, orElse: () => '') ?? '';

    out['jobTitle'] = (r['jobTitle'] as String?)?.trim() ?? (r['title'] as String?)?.trim() ?? (r['role'] as String?)?.trim() ?? '';
    out['displayId'] = (r['displayId'] as String?)?.trim() ?? (r['display_id'] as String?)?.trim() ?? out['uid'];

    out['email'] = (r['email'] as String?)?.trim() ?? '';
    out['phone'] = (r['phone'] as String?)?.trim() ?? '';
    out['bio'] = (r['bio'] as String?)?.trim() ?? (r['about'] as String?)?.trim() ?? '';

    // city & club (optional enhancements)
    out['city'] = (r['city'] as String?)?.trim() ?? (r['location'] as String?)?.trim() ?? '';
    out['club'] = (r['club'] as String?)?.trim() ?? '';

    // skills normalization
    final skillsRaw = r['skills'];
    List<String> skills = [];
    try {
      if (skillsRaw is List) {
        skills = skillsRaw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).cast<String>().toList();
      } else if (skillsRaw is String) {
        final s = skillsRaw.trim();
        if (s.startsWith('[') && s.endsWith(']')) {
          final decoded = jsonDecode(s);
          if (decoded is List) skills = decoded.map((e) => e?.toString() ?? '').where((x) => x.isNotEmpty).cast<String>().toList();
        } else if (s.contains(',')) {
          skills = s.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        } else if (s.isNotEmpty) {
          skills = [s];
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ [BoxHub][UserService] skills normalization failed: $e');
      debugPrint(st.toString());
      skills = [];
    }
    out['skills'] = skills;

    // providerData: keep as structured list
    try {
      if (r['providerData'] is List) {
        out['providerData'] = (r['providerData'] as List).map((e) => e is Map ? Map<String, dynamic>.from(e) : {'raw': e.toString()}).toList();
      } else if (r['providerData'] != null) {
        out['providerData'] = [r['providerData'].toString()];
      } else {
        out['providerData'] = [];
      }
    } catch (_) {
      out['providerData'] = [];
    }

    // createdAt / updatedAt -> keep Timestamp when present
    dynamic created = r['createdAt'] ?? r['created_at'];
    dynamic updated = r['updatedAt'] ?? r['updated_at'];
    Timestamp? createdTs;
    Timestamp? updatedTs;

    if (created is Timestamp) {
      createdTs = created;
      out['_raw_createdAt'] = created;
    } else if (created is DateTime) {
      createdTs = Timestamp.fromDate(created);
      out['_raw_createdAt'] = created;
    } else if (created is String) {
      final dt = DateTime.tryParse(created);
      if (dt != null) {
        createdTs = Timestamp.fromDate(dt);
        out['_raw_createdAt'] = created;
      } else {
        out['_raw_createdAt'] = created;
      }
    } else {
      out['_raw_createdAt'] = created;
    }

    if (updated is Timestamp) {
      updatedTs = updated;
      out['_raw_updatedAt'] = updated;
    } else if (updated is DateTime) {
      updatedTs = Timestamp.fromDate(updated);
      out['_raw_updatedAt'] = updated;
    } else if (updated is String) {
      final dt = DateTime.tryParse(updated);
      if (dt != null) {
        updatedTs = Timestamp.fromDate(dt);
        out['_raw_updatedAt'] = updated;
      } else {
        out['_raw_updatedAt'] = updated;
      }
    } else {
      out['_raw_updatedAt'] = updated;
    }

    out['createdAt'] = createdTs;
    out['updatedAt'] = updatedTs;

    out['_raw'] = r;
    out['age'] = (r['age'] is String) ? r['age'] : (r['age']?.toString() ?? '');
    out['gender'] = (r['gender'] as String?)?.trim() ?? '';

    debugPrint('✅ [BoxHub][UserService] Normalization complete for doc $docId -> canonical keys: ${out.keys.toList()}');
    return out;
  }

  /// Stream user profile by uid, watches both 'users' and 'usersL' and picks the first that exists.
  Stream<UserProfile?> streamUserProfile(String uid) {
    debugPrint('➡️ [BoxHub][UserService] streamUserProfile() subscribe uid=$uid');
    final refs = _docRefsForUid(uid);
    final controller = StreamController<UserProfile?>.broadcast();

    controller.onListen = () {
      debugPrint('ℹ️ [BoxHub][UserService] onListen attaching listeners for uid=$uid');
      final latest = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final subs = <StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>[];

      void recomputeAndEmit() {
        try {
          DocumentSnapshot<Map<String, dynamic>>? chosen;
          if (latest.containsKey('users') && latest['users']!.exists) {
            chosen = latest['users'];
            debugPrint('ℹ️ [BoxHub][UserService] chosen source: users');
          } else if (latest.containsKey('usersL') && latest['usersL']!.exists) {
            chosen = latest['usersL'];
            debugPrint('ℹ️ [BoxHub][UserService] chosen source: usersL');
          } else {
            debugPrint('ℹ️ [BoxHub][UserService] no doc found yet for uid=$uid -> emitting null');
            controller.add(null);
            return;
          }

          final raw = chosen!.data() ?? <String, dynamic>{};
          try {
            final rawJson = jsonEncode(raw);
            final truncated = rawJson.length > 800 ? rawJson.substring(0, 800) + '... (truncated)' : rawJson;
            debugPrint('🔔 snapshot raw (truncated) for uid=$uid: $truncated');
          } catch (_) {
            debugPrint('🔔 snapshot raw (non-json) for uid=$uid: ${raw.toString()}');
          }

          final normalized = _normalizeDocData(chosen.id, Map<String, dynamic>.from(raw));
          try {
            final profile = UserProfile.fromMap(normalized);
            debugPrint('✅ emitting profile uid=${profile.uid}');
            controller.add(profile);
          } catch (e, st) {
            debugPrint('❌ [BoxHub][UserService] UserProfile.fromMap failed: $e');
            debugPrint(st.toString());
            controller.add(null);
          }
        } catch (e, st) {
          debugPrint('❌ [BoxHub][UserService] recomputeAndEmit() error: $e');
          debugPrint(st.toString());
          controller.add(null);
        }
      }

      refs.forEach((key, ref) {
        final sub = ref.snapshots().listen((snap) {
          debugPrint('🔔 update from $key for uid=$uid -> exists=${snap.exists}');
          latest[key] = snap;
          recomputeAndEmit();
        }, onError: (err, st) {
          debugPrint('⚠️ [BoxHub][UserService] snapshot error on $key for uid=$uid -> $err');
          debugPrint(st.toString());
        });
        subs.add(sub);
      });

      controller.onCancel = () async {
        debugPrint('ℹ️ [BoxHub][UserService] onCancel -> cancelling ${subs.length} subscriptions for uid=$uid');
        for (final s in subs) await s.cancel();
      };
    };

    return controller.stream;
  }

  /// Single-read user profile by uid.
  Future<UserProfile?> getUserProfile(String uid) async {
    debugPrint('➡️ [BoxHub][UserService] getUserProfile() - uid=$uid');
    final refs = _docRefsForUid(uid);

    for (final key in ['users', 'usersL']) {
      final ref = refs[key];
      if (ref == null) continue;
      try {
        debugPrint('ℹ️ [BoxHub][UserService] Checking $key...');
        final snap = await ref.get();
        debugPrint('ℹ️ [BoxHub][UserService] Document $key/${snap.id} exists=${snap.exists}');
        if (snap.exists) {
          final raw = snap.data() ?? <String, dynamic>{};
          final normalized = _normalizeDocData(snap.id, Map<String, dynamic>.from(raw));
          try {
            final profile = UserProfile.fromMap(normalized);
            debugPrint('✅ [BoxHub][UserService] Found profile in $key uid=${profile.uid}');
            return profile;
          } catch (e, st) {
            debugPrint('❌ [BoxHub][UserService] fromMap failed for $key: $e');
            debugPrint(st.toString());
            return null;
          }
        }
      } catch (e, st) {
        debugPrint('⚠️ [BoxHub][UserService] getUserProfile() error reading $key: $e');
        debugPrint(st.toString());
      }
    }

    debugPrint('ℹ️ [BoxHub][UserService] getUserProfile() - not found for uid=$uid');
    return null;
  }

  /// Update specific fields for a user document.
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    debugPrint('➡️ [BoxHub][UserService] updateUserFields() uid=$uid keys=${fields.keys.toList()}');
    final ref = _fs.collection('users').doc(uid);
    final updates = Map<String, dynamic>.from(fields);
    updates['updatedAt'] = FieldValue.serverTimestamp();
    try {
      await ref.set(updates, SetOptions(merge: true));
      debugPrint('✅ [BoxHub][UserService] updateUserFields() success -> users/$uid');
    } catch (e, st) {
      debugPrint('❌ [BoxHub][UserService] updateUserFields() failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Upload profile/background image to Firebase Storage and return download URL.
  Future<String> uploadUserImage({
    required String uid,
    File? file,
    required String pathType,
    Uint8List? bytes,
    String? contentType,
  }) async {
    debugPrint('➡️ [BoxHub][UserService] uploadUserImage() uid=$uid pathType=$pathType');
    final ext = pathType.contains('.') ? '' : '.jpg';
    final storagePath = 'userProfiles/$uid/$pathType$ext';
    final ref = _storage.ref().child(storagePath);

    try {
      UploadTask uploadTask;
      final metadata = SettableMetadata(contentType: contentType ?? 'image/jpeg');
      if (file != null) {
        debugPrint('ℹ️ [BoxHub][UserService] uploadUserImage -> uploading File to $storagePath');
        uploadTask = ref.putFile(file, metadata);
      } else if (bytes != null) {
        debugPrint('ℹ️ [BoxHub][UserService] uploadUserImage -> uploading bytes (${bytes.length} bytes) to $storagePath');
        uploadTask = ref.putData(bytes, metadata);
      } else {
        throw ArgumentError('Either file or bytes must be provided for uploadUserImage.');
      }

      final snap = await uploadTask;
      final url = await snap.ref.getDownloadURL();
      debugPrint('✅ [BoxHub][UserService] uploadUserImage complete -> $url');
      return url;
    } catch (e, st) {
      debugPrint('❌ [BoxHub][UserService] uploadUserImage failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Delete a single user image (profile/background).
  Future<void> deleteUserImage(String uid, String pathType) async {
    final storagePath = 'userProfiles/$uid/$pathType.jpg';
    final ref = _storage.ref().child(storagePath);
    try {
      await ref.delete();
      debugPrint('✅ [BoxHub][UserService] deleteUserImage deleted $storagePath');
    } catch (e) {
      debugPrint('⚠️ [BoxHub][UserService] deleteUserImage failed (maybe missing): $e');
    }
  }

  /// Delete all user images under userProfiles/$uid
  Future<void> deleteAllUserImages(String uid) async {
    final dirRef = _storage.ref().child('userProfiles/$uid');
    try {
      final listResult = await dirRef.listAll();
      for (final item in listResult.items) {
        await item.delete();
        debugPrint('🗑️ [BoxHub][UserService] deleteAllUserImages deleted ${item.fullPath}');
      }
    } catch (e, st) {
      debugPrint('❌ [BoxHub][UserService] deleteAllUserImages failed: $e');
      debugPrint(st.toString());
    }
  }

  /// Delete user profile document and associated images.
  Future<void> deleteUserProfile(String uid) async {
    debugPrint('➡️ [BoxHub][UserService] deleteUserProfile() uid=$uid');
    final ref = _fs.collection('users').doc(uid);
    try {
      await ref.delete();
      debugPrint('✅ [BoxHub][UserService] deleteUserProfile removed users/$uid');
    } catch (e, st) {
      debugPrint('⚠️ [BoxHub][UserService] deleteUserProfile failed deleting users/$uid: $e');
      debugPrint(st.toString());
    }
    await deleteAllUserImages(uid);
  }

  /// Convenience: Save profile fields and optionally upload images in one operation.
  Future<void> saveProfileWithImages({
    required String uid,
    File? newProfileFile,
    File? newBackgroundFile,
    Map<String, dynamic>? fieldsToUpdate,
    Uint8List? profileBytes,
    Uint8List? backgroundBytes,
  }) async {
    debugPrint('➡️ [BoxHub][UserService] saveProfileWithImages() uid=$uid');
    final updates = <String, dynamic>{};
    if (fieldsToUpdate != null) updates.addAll(fieldsToUpdate);

    try {
      if (newProfileFile != null || profileBytes != null) {
        debugPrint('ℹ️ [BoxHub][UserService] Saving profile image...');
        final url = await uploadUserImage(uid: uid, file: newProfileFile, pathType: 'profile', bytes: profileBytes);
        updates['profileImageUrl'] = url;
      }
      if (newBackgroundFile != null || backgroundBytes != null) {
        debugPrint('ℹ️ [BoxHub][UserService] Saving background image...');
        final url = await uploadUserImage(uid: uid, file: newBackgroundFile, pathType: 'background', bytes: backgroundBytes);
        updates['backgroundImageUrl'] = url;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        final ref = _fs.collection('users').doc(uid);
        await ref.set(updates, SetOptions(merge: true));
        debugPrint('✅ [BoxHub][UserService] saveProfileWithImages wrote keys=${updates.keys.toList()} to users/$uid');
      } else {
        debugPrint('ℹ️ [BoxHub][UserService] saveProfileWithImages nothing to update.');
      }
    } catch (e, st) {
      debugPrint('❌ [BoxHub][UserService] saveProfileWithImages failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }
}
