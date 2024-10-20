// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FileUploadProvider extends ChangeNotifier {
  final _storageRef = FirebaseStorage.instance.ref();

  Future<String?> fileUpload(
      {required File file, required String fileName}) async {
    try {
      final uploadTask = _storageRef.child(fileName).putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print(e);
    }
    return null;
  }
}
