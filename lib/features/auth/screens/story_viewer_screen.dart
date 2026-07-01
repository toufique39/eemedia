import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController controller = StoryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(body: Center(child: Text("No stories available")));
    }

    final storyItems = widget.stories
        .sublist(widget.initialIndex)
        .map<StoryItem?>((story) {
          final imageUrl = story['imageUrl'] ?? '';

          if (imageUrl.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
            return null;
          }

          return StoryItem.pageImage(
            url: imageUrl,
            controller: controller,
            duration: const Duration(seconds: 5),
            loadingWidget: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            caption: Text(
              story['userData']?['name'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        })
        .whereType<StoryItem>()
        .toList();

    return Scaffold(
      body: StoryView(
        storyItems: storyItems,

        controller: controller,

        repeat: false,

        inline: false,

        onComplete: () {
          if (mounted) Navigator.pop(context);
        },

        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down && mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
