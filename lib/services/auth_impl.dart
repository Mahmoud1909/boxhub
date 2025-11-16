
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignInException implements Exception {
  final String code;
  final String message;
  SignInException(this.code, this.message);

  @override
  String toString() => 'SignInException($code): $message';
}


Future<UserCredential?> signInWithGoogle() async {
  debugPrint("🚀 [BoxHub][Auth] Starting Google Sign-In...");

  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    late UserCredential userCredential;

    if (kIsWeb) {
      debugPrint("[BoxHub][Auth][WEB] Using GoogleAuthProvider popup for web.");
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      userCredential = await auth.signInWithPopup(provider);
    } else if (Platform.isAndroid || Platform.isIOS) {
      debugPrint("[BoxHub][Auth][MOBILE] Using GoogleSignIn on mobile.");
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("[BoxHub][Auth] Google sign-in cancelled by user.");
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      userCredential = await auth.signInWithCredential(credential);
    } else {
      debugPrint("[BoxHub][Auth] Platform not supported for Google Sign-In.");
      throw SignInException('platform_not_supported',
          'Google Sign-In is supported only on web, Android and iOS.');
    }

    debugPrint("✅ [BoxHub][Auth] Google Sign-In success for ${userCredential.user?.email}");
    return userCredential;
  } catch (e, st) {
    debugPrint("💥 [BoxHub][Auth] Google Sign-In failed: $e");
    debugPrint(st.toString());
    if (e is SignInException) rethrow;
    throw SignInException('unexpected', e.toString());
  }
}

/// Sign in with Apple.
/// - On web: uses OAuthProvider popup for apple.com.
/// - On iOS (native): uses sign_in_with_apple to get credential then Firebase sign-in.
/// - Returns null if user cancels the flow or platform not supported.
Future<UserCredential?> signInWithApple() async {
  debugPrint("🚀 [BoxHub][Auth] Starting Apple Sign-In...");

  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    late UserCredential userCredential;

    if (kIsWeb) {
      debugPrint("[BoxHub][Auth][WEB] Using OAuthProvider('apple.com') popup for web.");
      final provider = OAuthProvider('apple.com');
      provider.addScope('email');
      provider.addScope('name');
      userCredential = await auth.signInWithPopup(provider);
    } else if (Platform.isIOS) {
      debugPrint("[BoxHub][Auth][iOS] Starting native Apple sign-in flow.");
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      userCredential = await auth.signInWithCredential(oauthCredential);
    } else {
      debugPrint("[BoxHub][Auth] Apple Sign-In not supported on this platform.");
      throw SignInException('platform_not_supported',
          'Apple Sign-In is supported only on iOS and Web.');
    }

    debugPrint("✅ [BoxHub][Auth] Apple Sign-In success for ${userCredential.user?.email}");
    return userCredential;
  } catch (e, st) {
    debugPrint("💥 [BoxHub][Auth] Apple Sign-In failed: $e");
    debugPrint(st.toString());
    if (e is SignInException) rethrow;
    throw SignInException('unexpected', e.toString());
  }
}
