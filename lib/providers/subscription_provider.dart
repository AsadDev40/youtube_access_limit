// ignore_for_file: prefer_final_fields

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SubscriptionProvider with ChangeNotifier {
  Map<String, bool> _subscriptions = {};

  bool isSubscribed(String channelId) {
    return _subscriptions[channelId] ?? false;
  }

  void subscribe(String channelId) {
    _subscriptions[channelId] = true;
    notifyListeners();
  }

  void unSubscribe(String channelId) {
    _subscriptions[channelId] = false;
    notifyListeners();
  }
}
