// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/models/user_model.dart';
import 'package:kidsafe_youtube/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthProvider extends ChangeNotifier {
  User? get currentuser => FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final userCollection = FirebaseFirestore.instance.collection('users');
  final _authService = AuthService();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Utils.showToast('Password reset email sent');
    } catch (e) {
      Utils.showToast('Error: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _authService.signInWithEmailAndPassword(email, password);
  }

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    return await _authService.registerWithEmailAndPassword(email, password);
  }

  Future<void> addUserToFirestore(UserModel userModel) async {
    await userCollection.doc(userModel.uid).set(userModel.toJson());
  }

  Future<void> deleteUserDatatoFirestore() async {
    await userCollection.doc(currentuser!.uid).delete();
  }

  Future<UserModel> getUserFromFirestore(String uid) async {
    final user = await userCollection.doc(uid).get();
    return UserModel.fromJson(user.data()!);
  }

  Future<void> updateUserImage(String uid, String imageUrl) async {
    await userCollection.doc(uid).update({'profileImage': imageUrl});
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  Future<UserCredential> signUpWithGoogle() async {
    try {
      final res = await _authService.signInWithGoogle();
      final isNewUser = res.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        final userModel = UserModel(
            uid: res.user!.uid,
            profileImage: res.user!.photoURL,
            email: res.user!.email!,
            userName: res.user!.displayName!,
            createdAt: res.user!.metadata.creationTime!,
            isSubscribed: false,
            isTrial: false);

        await addUserToFirestore(userModel);
      }

      return res;
    } catch (e) {
      Utils.showToast('Error during Google sign-up: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final res = await _authService.signInWithGoogle();
      final userModel = UserModel(
          uid: res.user!.uid,
          profileImage: res.user!.photoURL,
          email: res.user!.email!,
          userName: res.user!.displayName!,
          createdAt: res.user!.metadata.creationTime!);

      addUserToFirestore(userModel);

      return res;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          profileImage: userCredential.user!.photoURL,
          email: userCredential.user!.email ?? '',
          userName:
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim(),
          createdAt: userCredential.user!.metadata.creationTime!,
        );

        await addUserToFirestore(userModel);
      }

      Utils.showToast('Successfully signed in with Apple');
      return userCredential;
    } catch (e) {
      Utils.showToast('Error during Apple sign-in: $e');
      return null;
    }
  }

  Future<UserCredential?> signUpWithApple() async {
    try {
      return await signInWithApple();
    } catch (e) {
      Utils.showToast('Error during Apple sign-up: $e');
      return null;
    }
  }

  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}
