import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String reaction) onReactionSelected;

  const ReactionPicker({super.key, required this.onReactionSelected});

  @override
  Widget build(BuildContext context) {
    final reactionsList = [
      {'emoji': '👍', 'type': 'like'},
      {'emoji': '❤️', 'type': 'love'},
      {'emoji': '😮', 'type': 'wow'},
      {'emoji': '😢', 'type': 'sad'},
      {'emoji': '😡', 'type': 'angry'},
      {'emoji': '🤣', 'type': 'haha'},
      {'emoji': '🐥', 'type': 'polti'},
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: reactionsList.map((reaction) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onReactionSelected(reaction['type']!);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    reaction['emoji']!,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
