import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kidsafe_youtube/models/subscription_model.dart';

class Subscriptionprovider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<SubscriptionModel> _subscriptions = [];

  Future<void> confirmSubscription(String userId, String planId) async {
    DateTime now = DateTime.now();
    DateTime trialEndDate = now.add(const Duration(days: 3));
    DateTime subscriptionEndDate;

    switch (planId) {
      case 'monthly_plan':
        subscriptionEndDate =
            trialEndDate.add(const Duration(days: 30)); // Monthly plan
        break;
      case 'yearly_plan':
        subscriptionEndDate =
            trialEndDate.add(const Duration(days: 365)); // Yearly plan
        break;
      case 'lifetime_plan':
        subscriptionEndDate =
            DateTime(2100, 12, 31); // Lifetime plan, far future date
        break;
      default:
        throw Exception('Unknown plan ID');
    }

    SubscriptionModel newSubscription = SubscriptionModel(
      planName: planId,
      startDate: now,
      endDate: subscriptionEndDate,
    );

    DocumentReference<Map<String, dynamic>> userDocRef =
        _firestore.collection('users').doc(userId);

    // Add the subscription to Firestore
    CollectionReference<Map<String, dynamic>> userSubscriptions =
        userDocRef.collection('subscriptions');
    await userSubscriptions.add(newSubscription.toJson());

    // Set user subscription status
    await userDocRef.update({
      'isSubscribed': true,
      'startDate': now.toIso8601String(),
      'endDate': subscriptionEndDate.toIso8601String(),
    });

    _subscriptions.add(newSubscription);
    notifyListeners();
  }

  Future<void> checkSubscriptionStatus(String userId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      DateTime? subscriptionEnd = userData['endDate'] != null
          ? DateTime.parse(userData['endDate'])
          : null;

      if (subscriptionEnd != null && DateTime.now().isAfter(subscriptionEnd)) {
        // If the subscription is expired, update the user's subscription status
        await _firestore.collection('users').doc(userId).update({
          'isSubscribed': false,
        });

        // Optionally, notify the listeners
        notifyListeners();
      }
    }
  }
}
