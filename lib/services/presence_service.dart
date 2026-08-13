import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService instance = PresenceService._internal();

  PresenceService._internal();

  factory PresenceService() {
    return instance;
  }

  bool _started = false;

  /// Start presence tracking.
  void start() {
    if (_started) return;

    _started = true;

    WidgetsBinding.instance.addObserver(this);

    // App starts in foreground.
    setOnline();
  }

  /// Stop presence tracking.
  Future<void> stop() async {
    if (!_started) return;

    _started = false;

    WidgetsBinding.instance.removeObserver(this);

    await setOffline();
  }

  /// User is online.
  static Future<void> setOnline() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Set Online Error: $e');
    }
  }

  /// User is offline.
  static Future<void> setOffline() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Set Offline Error: $e');
    }
  }

  /// Handle app lifecycle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        setOnline();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        setOffline();
        break;

      case AppLifecycleState.detached:
        setOffline();
        break;
    }
  }
}
