import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  List<File?> _selectedImages = [null, null, null];

  File? get selectedImage => _selectedImage;
  List<File?> get selectedImages => _selectedImages;

  void updateSelectedImage(File image) {
    _selectedImage = image;
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    final imgXFile = await _picker.pickImage(source: ImageSource.camera);
    if (imgXFile != null) {
      _selectedImage = File(imgXFile.path);
    }

    notifyListeners();
  }

  Future<void> pickImageFromGallery() async {
    final imgXFile = await _picker.pickImage(source: ImageSource.gallery);
    if (imgXFile != null) {
      _selectedImage = File(imgXFile.path);
    }

    notifyListeners();
  }

  void reset() {
    _selectedImage = null;
    _selectedImages = [];
    notifyListeners();
  }
}
