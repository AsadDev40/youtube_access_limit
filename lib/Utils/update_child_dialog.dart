// ignore_for_file: use_build_context_synchronously

import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateChildDialog {
  static Future<void> updateChildDialog(
      BuildContext context, String childUid) async {
    final childNameController = TextEditingController();
    final childUrlController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Child'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: childNameController,
                      decoration:
                          const InputDecoration(labelText: 'Child Name'),
                    ),
                    TextField(
                      controller: childUrlController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Image Url'),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final childProvider =
                        Provider.of<ChildProvider>(context, listen: false);
                    if (childNameController.text.isNotEmpty) {
                      await childProvider.updateChild(childUid,
                          childUrlController.text, childNameController.text);
                      await childProvider.getChilds();
                      Utils.showToast('Child added successfully');
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
