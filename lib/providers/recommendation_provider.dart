import 'dart:async';

import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  Timer? _debounce;

  int _refreshVersion = 0;

  int get refreshVersion => _refreshVersion;

  void requestRefresh() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(seconds: 10), () {
      _refreshVersion++;

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    super.dispose();
  }
}
