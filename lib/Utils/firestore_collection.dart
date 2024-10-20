// firestore collections constants
import 'package:cloud_firestore/cloud_firestore.dart';

final userCollection = FirebaseFirestore.instance.collection('users');
final recommendCollection =
    FirebaseFirestore.instance.collection('recommendation');

CollectionReference childrenCollection({required String parentId}) {
  return userCollection.doc(parentId).collection('child');
}
