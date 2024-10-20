// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidsafe_youtube/Utils/firestore_collection.dart';
import 'package:kidsafe_youtube/Utils/utils.dart';
import 'package:kidsafe_youtube/models/child_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ChildProvider extends ChangeNotifier {
  ChildModel? _currentChild;

  User? get currentuser => FirebaseAuth.instance.currentUser;

  List<ChildModel> _child = [];

  List<ChildModel> get child => _child;

  ChildModel? get currentChild => _currentChild;

// add child
  Future<void> addChildToFirestore(ChildModel childModel) async {
    await childrenCollection(parentId: currentuser!.uid)
        .doc(childModel.uid)
        .set(childModel.toJson());
  }

  // delete child
  Future<void> deleteChild(ChildModel child) async {
    await childrenCollection(parentId: currentuser!.uid)
        .doc(child.uid)
        .delete();
    await getChilds();
    Utils.showToast('Child deleted successfully');
  }

  // update child
  Future<void> updateChild(
      String childId, String newImageUrl, String newName) async {
    final childDocReference =
        childrenCollection(parentId: currentuser!.uid).doc(childId);

    try {
      EasyLoading.show();
      await childDocReference.update({
        'imageUrl': newImageUrl,
        'childname': newName,
      });
      await getChilds();
      EasyLoading.dismiss();
      print('Child updated successfully');
    } catch (e) {
      print('Error updating child: $e');
    }
  }

  // allow video for child

  Future<void> allowVideoForChild(
    String videoId,
    String childId,
  ) async {
    await childrenCollection(parentId: currentuser!.uid).doc(childId).update({
      'videos': FieldValue.arrayUnion([videoId]),
    });
  }

  // add channel for child
  Future<void> addChannelForChild(
    String channelId,
    String childId,
  ) async {
    await childrenCollection(parentId: currentuser!.uid).doc(childId).update({
      'channels': FieldValue.arrayUnion([channelId]),
    });
  }

  Future<List<ChildModel>> getChilds() async {
    _child = [];
    final res = await childrenCollection(parentId: currentuser!.uid).get();
    if (res.docs.isNotEmpty) {
      for (var data in res.docs) {
        _child.add(ChildModel.fromJson(data.data() as Map<String, dynamic>));
      }
    }
    return _child;
  }

  Future<List<ChildModel>> _filterChilds(String parentId) async {
    final child = <ChildModel>[];
    final res = await childrenCollection(parentId: parentId).get();
    if (res.docs.isNotEmpty) {
      for (var data in res.docs) {
        child.add(ChildModel.fromJson(data.data() as Map<String, dynamic>));
      }
    }

    return child;
  }

  Future<void> getLoggedInChild(
      {required String parentEmail,
      required String childName,
      required String securityCode}) async {
    final res =
        await userCollection.where('email', isEqualTo: parentEmail).get();
    final childrens = await _filterChilds(res.docs.first.data()['uid']);
    if (childrens.isNotEmpty) {
      _currentChild = childrens.firstWhere((element) =>
          element.childName == childName &&
          element.securtiyCode == securityCode);

      notifyListeners();
    }
  }

  Future<void> deleteChannelFromChild(String channelId, String childId) async {
    try {
      EasyLoading.show();

      // Remove the channel from Firestore
      await childrenCollection(parentId: currentuser!.uid).doc(childId).update({
        'channels': FieldValue.arrayRemove([channelId]),
      });

      // Update the current child's channel list locally
      _currentChild?.channels.remove(channelId);

      // Notify listeners to refresh the UI
      notifyListeners();

      EasyLoading.dismiss();
      Utils.showToast('Channel deleted successfully');
    } catch (e) {
      EasyLoading.dismiss();
      print('Error deleting channel: $e');
    }
  }

  // Delete a video from the child's collection
  Future<void> deleteVideoFromChild(String videoId, String childId) async {
    await childrenCollection(parentId: currentuser!.uid).doc(childId).update({
      'videos': FieldValue.arrayRemove([videoId]),
    });

    // Update the local list and notify listeners
    _currentChild?.videos.remove(videoId);
    notifyListeners();

    Utils.showToast('Video deleted successfully');
  }
}
