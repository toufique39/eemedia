import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eemedia/eemedia_backend/app/services/recommendation_api_service.dart';
import 'package:eemedia/features/home/widgets/reel_item.dart';
import 'package:eemedia/services/screen_time_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReelsFeedScreen extends StatefulWidget {
  final bool isActive;

  const ReelsFeedScreen({super.key, required this.isActive});

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen> {
  bool _isLoadingData = true;
  List<String> _recommendedReelIds = [];
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _loadFeedDependencies();
  }

  Future<void> _loadFeedDependencies() async {
    if (mounted) {
      setState(() => _isLoadingData = true);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingData = false);
      return;
    }

    try {
      final results = await Future.wait([
        RecommendationApiService.getRecommendedReelIds(
          userId: user.uid,
          limit: 30,
        ),
        ScreenTimeService.hasReachedEntertainmentLimit(),
      ]);

      if (!mounted) return;

      setState(() {
        _recommendedReelIds = results[0] as List<String>;
        _limitReached = results[1] as bool;
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('Error loading feed dependencies: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  List<QueryDocumentSnapshot> _processFeed({
    required List<QueryDocumentSnapshot> allReels,
    required List<String> recommendedIds,
    required bool isLimitReached,
  }) {
    List<QueryDocumentSnapshot> baseFeed = [];

    if (recommendedIds.isNotEmpty) {
      final reelsById = {for (final reel in allReels) reel.id: reel};
      baseFeed = recommendedIds
          .where(reelsById.containsKey)
          .map((id) => reelsById[id]!)
          .toList();
    }

    if (baseFeed.isEmpty) {
      baseFeed = List<QueryDocumentSnapshot>.from(allReels);
    }

    if (isLimitReached) {
      final educationalReels = baseFeed.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['category']?.toString().toLowerCase() == 'education';
      }).toList();

      return educationalReels.isNotEmpty ? educationalReels : baseFeed;
    }

    return baseFeed;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reels')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorScreen(
              'Could not load reels.\n${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final allReels = snapshot.data!.docs;

          if (allReels.isEmpty) {
            return const Center(
              child: Text(
                'No Reels Yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final finalReels = _processFeed(
            allReels: allReels,
            recommendedIds: _recommendedReelIds,
            isLimitReached: _limitReached,
          );

          if (finalReels.isEmpty) {
            return const Center(
              child: Text(
                'No reels available under current preference.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFeedDependencies,
            color: Colors.white,
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: finalReels.length,
              itemBuilder: (context, index) {
                final reelDoc = finalReels[index];
                final reelData = reelDoc.data() as Map<String, dynamic>;

                return ReelItem(
                  key: ValueKey(reelDoc.id),
                  reelId: reelDoc.id,
                  reelData: reelData,
                  isActive: widget.isActive,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFeedDependencies,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
