// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/pages/offline_shorts_page.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kidsafe_youtube/pages/home/manage_child_screen.dart';
import 'package:kidsafe_youtube/pages/main_page.dart';
import 'package:kidsafe_youtube/Utils/firestore_collection.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/models/user_model.dart';
import 'package:kidsafe_youtube/providers/auth_provider.dart';
import 'package:kidsafe_youtube/providers/file_upload_provider.dart';
import 'package:kidsafe_youtube/providers/image_picker_provider.dart';
import 'package:kidsafe_youtube/widgets/cached_image.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final imageProvider = Provider.of<ImagePickerProvider>(context);

    return Drawer(
      child: Column(
        children: [
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: userCollection.doc(authProvider.currentuser!.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.black),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError || !snapshot.hasData) {
                return const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.black),
                  child: Center(child: Text('Error loading user')),
                );
              } else {
                final user = UserModel.fromJson(snapshot.data!.data()!);

                return DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              builder: (context) => _buildProfilePhotoPicker(
                                  context, imageProvider, authProvider, user),
                            );
                          },
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: CachedImage(
                                user.profileImage ??
                                    'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                                isRound: true,
                                radius: 40),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.userName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Children'),
            leading: const Icon(Icons.child_care),
            onTap: () {
              Utils.navigateTo(context, const ChildrenScreen());
            },
          ),
          ListTile(
            title: const Text('Offline shorts'),
            leading: const Icon(Icons.video_call),
            onTap: () {
              Utils.navigateTo(context, const OfflineShortsPage());
            },
          ),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await authProvider.logout();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('parent', false);
              Utils.pushAndRemovePrevious(context, const MainPage());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoPicker(
      BuildContext context,
      ImagePickerProvider imageProvider,
      AuthProvider authProvider,
      UserModel user) {
    return Container(
      height: 150,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const Text('Choose Profile Photo', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await imageProvider.pickImageFromCamera();
                  Navigator.pop(context);
                  await _updateProfilePhoto(
                      context, imageProvider, authProvider, user);
                },
                icon: const Icon(Icons.camera),
                label: const Text('Camera'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await imageProvider.pickImageFromGallery();
                  Navigator.pop(context);
                  await _updateProfilePhoto(
                      context, imageProvider, authProvider, user);
                },
                icon: const Icon(Icons.image),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePhoto(
      BuildContext context,
      ImagePickerProvider imageProvider,
      AuthProvider authProvider,
      UserModel user) async {
    if (imageProvider.selectedImage != null) {
      final uploadProvider =
          Provider.of<FileUploadProvider>(context, listen: false);
      final url = await uploadProvider.fileUpload(
        file: imageProvider.selectedImage!,
        fileName: 'user-image-${user.uid}',
      );
      if (url != null) {
        await authProvider.updateUserImage(user.uid, url);
        imageProvider.reset();
      }
    }
  }
}
