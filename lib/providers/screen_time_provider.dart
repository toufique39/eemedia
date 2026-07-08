import 'package:flutter/material.dart';
import '../services/screen_time_service.dart';

class ScreenTimeProvider extends ChangeNotifier {
  int _entertainmentSeconds = 0;
  int _remainingSeconds = 60;
  bool _limitReached = false;
  bool _loading = true;

  int get entertainmentSeconds => _entertainmentSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get limitReached => _limitReached;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();

    _entertainmentSeconds = await ScreenTimeService.getEntertainmentSeconds();

    _remainingSeconds =
        await ScreenTimeService.getRemainingEntertainmentSeconds();

    _limitReached = await ScreenTimeService.hasReachedEntertainmentLimit();

    _loading = false;

    notifyListeners();
  }

  Future<void> addWatchTime({
    required String category,
    required int watchedSeconds,
  }) async {
    await ScreenTimeService.addWatchTime(
      category: category,
      watchedSeconds: watchedSeconds,
    );

    await refresh();
  }
}
