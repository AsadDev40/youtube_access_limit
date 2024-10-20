// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:kidsafe_youtube/providers/auth_provider.dart';
import 'package:kidsafe_youtube/utilities/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/providers/child_provider.dart';
import 'package:provider/provider.dart';
import 'package:kidsafe_youtube/Utils/add_child_dialog.dart';
import 'package:kidsafe_youtube/Utils/update_child_dialog.dart';
import 'package:kidsafe_youtube/pages/home/child/child_qr_code.dart';
import 'package:kidsafe_youtube/pages/home/child/child_home_page.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final parentuid =
        Provider.of<AuthProvider>(context, listen: false).currentuser!.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(),
      body: FutureBuilder(
        future: childProvider.getChilds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || childProvider.child.isEmpty) {
            return Center(
                child:
                    Text('No child found', style: theme.textTheme.labelLarge));
          } else {
            return ListView.builder(
              itemCount: childProvider.child.length,
              itemBuilder: (context, index) {
                final child = childProvider.child[index];
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: () async {
                      EasyLoading.show();
                      final parentEmail =
                          Provider.of<AuthProvider>(context, listen: false)
                              .currentuser!
                              .email;
                      await childProvider.getLoggedInChild(
                        parentEmail: parentEmail as String,
                        childName: child.childName,
                        securityCode: child.securtiyCode,
                      );
                      EasyLoading.dismiss();
                      Utils.navigateTo(context, ChildHomePage());
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(child.imageUrl),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 80),
                          child: Text(child.childName,
                              style: theme.textTheme.labelLarge),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await Provider.of<ChildProvider>(context,
                                        listen: false)
                                    .deleteChild(child);
                              },
                              icon: Icon(Icons.delete,
                                  color: theme.iconTheme.color),
                            ),
                            IconButton(
                              onPressed: () {
                                UpdateChildDialog.updateChildDialog(
                                    context, child.uid);
                              },
                              icon: Icon(Icons.edit,
                                  color: theme.iconTheme.color),
                            ),
                            IconButton(
                              onPressed: () {
                                Utils.navigateTo(
                                    context, QRCodeScreen(child: child));
                              },
                              icon: Icon(Icons.qr_code,
                                  color: theme.iconTheme.color),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        onPressed: () {
          AddChildDialog.showAddChildDialog(context, parentuid);
        },
        tooltip: 'Add Child',
        child: Icon(Icons.add,
            color: theme.floatingActionButtonTheme.foregroundColor),
      ),
    );
  }
}
