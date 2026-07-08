import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:eemedia/features/home/widgets/reel_item.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/screen_time_provider.dart';

class ReelsFeedScreen extends StatefulWidget {
  final bool isActive;

  const ReelsFeedScreen({super.key, required this.isActive});

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen> {
  bool _isLoadingData = true;
  List<String> _recommendedReelIds = [];
  late final PageController _pageController; // ✅
  int _currentIndex = 0; // ✅

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _loadFeedDependencies();

    // ✅ build এর বাইরে provider refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ScreenTimeProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // ✅
    super.dispose();
  }

  void _handleLimitReached() async {
    await context.read<ScreenTimeProvider>().refresh();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "📚 Entertainment limit reached.\nEducational feed activated.",
        ),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      _currentIndex = 0;
    });

    _pageController.jumpToPage(0);
  }

  Future<void> _loadFeedDependencies() async {
    if (mounted) {
      setState(() {
        _isLoadingData = true;
      });
    }

    // Recommendation আপাতত Disable
    _recommendedReelIds = [];

    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  List<QueryDocumentSnapshot> _processFeed({
  required List<QueryDocumentSnapshot> allReels,
  required bool isLimitReached,
}) {

  if (!isLimitReached) {
    return allReels;
  }

  final educationalReels = allReels.where((doc) {

    final data = doc.data() as Map<String, dynamic>;

    final category =
        (data["finalCategory"] ?? "")
            .toString()
            .toLowerCase();

    return category == "education";

  }).toList();

  return educationalReels;
}

  @override
  Widget build(BuildContext context) {
    final screenProvider = context.watch<ScreenTimeProvider>();

    // ✅ loading screen
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reels')
           
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
           
            isLimitReached: screenProvider.limitReached,
          );

          if (finalReels.isEmpty) {
            return const Center(
              child: Text(
                'No educational reels available yet.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFeedDependencies,
            color: Colors.white,
            child: PageView.builder(
              controller: _pageController, // ✅
              scrollDirection: Axis.vertical,
              itemCount: finalReels.length,
              // ✅ current page track করো
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final reelDoc = finalReels[index];
                final reelData = reelDoc.data() as Map<String, dynamic>;

                return ReelItem(
                  key: ValueKey(reelDoc.id),
                  reelId: reelDoc.id,
                  reelData: reelData,
                  // ✅ শুধু current index active
                  isActive: widget.isActive && index == _currentIndex,
                  // ✅ শুধু setState — reload না
                  onLimitReached: _handleLimitReached,
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
