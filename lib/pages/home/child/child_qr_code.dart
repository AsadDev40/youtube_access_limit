import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth import
import 'package:kidsafe_youtube/models/child_model.dart';

class QRCodeScreen extends StatelessWidget {
  final ChildModel child;

  const QRCodeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? userEmail = user?.email;

    final String qrData =
        'Name: ${child.childName}, Security Code: ${child.securtiyCode}, Email: $userEmail';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Child QR Code'),
      ),
      body: Center(
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 300.0,
          gapless: false,
        ),
      ),
    );
  }
}
