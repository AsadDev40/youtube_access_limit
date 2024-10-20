// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/pages/home/child/child_home_page.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class QRCodeScanScreen extends StatefulWidget {
  const QRCodeScanScreen({super.key});

  @override
  _QRCodeScanScreenState createState() => _QRCodeScanScreenState();
}

class _QRCodeScanScreenState extends State<QRCodeScanScreen> {
  final QRCodeDartScanController _controller = QRCodeDartScanController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: QRCodeDartScanView(
        controller: _controller,
        scanInvertedQRCode: true,
        onCapture: (Result result) async {
          EasyLoading.show(status: 'Processing...');
          await _processQRCodeData(result.text);
        },
      ),
    );
  }

  Future<void> _processQRCodeData(String data) async {
    final parts = data.split(', ');
    final namePart =
        parts.firstWhere((part) => part.startsWith('Name: '), orElse: () => '');
    final securityCodePart = parts.firstWhere(
        (part) => part.startsWith('Security Code: '),
        orElse: () => '');
    final emailPart = parts.firstWhere((part) => part.startsWith('Email: '),
        orElse: () => '');

    final name = namePart.replaceFirst('Name: ', '');
    final securityCode = securityCodePart.replaceFirst('Security Code: ', '');
    final email = emailPart.replaceFirst('Email: ', '');

    await _loginChild(name, securityCode, email);
  }

  Future<void> _loginChild(
      String name, String securityCode, String email) async {
    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    await childProvider.getLoggedInChild(
        parentEmail: email, childName: name, securityCode: securityCode);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('child', true);
    await prefs.setBool('showbutton', false);
    await prefs.setString('parentEmail', email);
    await prefs.setString('childName', name);
    await prefs.setString('Securitycode', securityCode);

    EasyLoading.dismiss();
    Utils.pushAndRemovePrevious(context, const ChildHomePage());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
