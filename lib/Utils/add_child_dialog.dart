// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/providers/image_picker_provider.dart';
import 'package:kidsafe_youtube/providers/file_upload_provider.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:kidsafe_youtube/models/child_model.dart';
import 'package:uuid/uuid.dart';

class AddChildDialog {
  static Future<void> showAddChildDialog(
      BuildContext context, String parentUid) async {
    final nameController = TextEditingController();
    final securityCodeController = TextEditingController();
    final imageProvider =
        Provider.of<ImagePickerProvider>(context, listen: false);
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor, // Use theme color
              title: Text('Add Child',
                  style: theme.textTheme.headlineLarge), // Use theme text style
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          builder: (context) => SizedBox(
                            height: 150,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.camera,
                                      color: theme.iconTheme.color),
                                  title: Text('Take a photo',
                                      style: theme.textTheme.labelLarge),
                                  onTap: () async {
                                    await imageProvider.pickImageFromCamera();
                                    Navigator.of(context).pop();
                                    setState(
                                        () {}); // Refresh the dialog content
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.image,
                                      color: theme.iconTheme.color),
                                  title: Text('Choose from gallery',
                                      style: theme.textTheme.labelLarge),
                                  onTap: () async {
                                    await imageProvider.pickImageFromGallery();
                                    Navigator.of(context).pop();
                                    setState(
                                        () {}); // Refresh the dialog content
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: theme
                              .colorScheme.surface, // Use theme surface color
                          border: Border.all(
                              color: theme
                                  .dividerColor), // Use theme divider color
                        ),
                        child: isUploading
                            ? Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 4.0,
                                    color: theme.primaryColor),
                              )
                            : imageProvider.selectedImage != null
                                ? Image.file(
                                    imageProvider.selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: theme.iconTheme.color,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Child Name',
                        labelStyle:
                            theme.textTheme.labelLarge, // Use theme text style
                      ),
                    ),
                    TextField(
                      controller: securityCodeController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Security Code',
                        labelStyle:
                            theme.textTheme.labelLarge, // Use theme text style
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel',
                      style:
                          theme.textTheme.bodyMedium), // Use theme text style
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final securitycode = securityCodeController.text.trim();
                    if (name.isNotEmpty && securitycode.isNotEmpty) {
                      if (imageProvider.selectedImage != null && !isUploading) {
                        setState(() {
                          isUploading = true;
                        });
                        final uploadProvider = Provider.of<FileUploadProvider>(
                            context,
                            listen: false);
                        final pictureUrl = await uploadProvider.fileUpload(
                          file: imageProvider.selectedImage!,
                          fileName: 'child-image-$name',
                        );
                        setState(() {
                          isUploading = false;
                        });
                        if (pictureUrl != null) {
                          final childProvider = Provider.of<ChildProvider>(
                              context,
                              listen: false);
                          final String uniqueChildUid = const Uuid().v4();

                          await childProvider.addChildToFirestore(ChildModel(
                              uid: uniqueChildUid,
                              childName: name,
                              securtiyCode: securitycode,
                              imageUrl: pictureUrl,
                              videos: [],
                              channels: []));
                          await childProvider.getChilds();

                          Utils.showToast('Child added successfully');

                          imageProvider.reset();
                          Navigator.of(context).pop();
                        } else {
                          Utils.showToast('Failed to upload child image');
                        }
                      } else {
                        Utils.showToast('Please select a child image');
                      }
                    } else {
                      Utils.showToast('Please fill in all fields');
                    }
                  },
                  child: Text('Save',
                      style: theme.textTheme.bodyLarge), // Use theme text style
                ),
              ],
            );
          },
        );
      },
    );
  }
}
