import 'dart:async';
import 'package:flutter/material.dart';

class TrackingProvider extends ChangeNotifier {
  int funTime = 0; // seconds
  Timer? _timer;

  bool isBlocked = false;

  void startTracking(String type) {
    stopTracking();

    if (type == "funny") {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        funTime++;

        if (funTime >= 300) {
          // demo: 5 min (later 5 hours)
          isBlocked = true;
          stopTracking();
        }

        notifyListeners();
      });
    }
  }

  void stopTracking() {
    _timer?.cancel();
  }
}
