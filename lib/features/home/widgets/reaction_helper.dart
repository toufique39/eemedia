import 'package:flutter/material.dart';

class ReactionHelper {
  static String getReactionEmoji(String? reaction) {
    switch (reaction) {
      case 'like':
        return '👍';

      case 'love':
        return '❤️';

      case 'wow':
        return '😮';

      case 'sad':
        return '😢';

      case 'angry':
        return '😡';

      case 'haha':
        return '🤣';

      case 'polti':
        return '🐥';

      default:
        return '👍';
    }
  }

  static String getReactionLabel(String? reaction) {
    switch (reaction) {
      case 'like':
        return 'Like';

      case 'love':
        return 'Love';

      case 'wow':
        return 'Wow';

      case 'sad':
        return 'Sad';

      case 'angry':
        return 'Angry';

      case 'haha':
        return 'Haha';

      case 'polti':
        return 'Polti';

      default:
        return 'Like';
    }
  }

  static Color getReactionColor(String? reaction) {
    switch (reaction) {
      case 'like':
        return Colors.blue;

      case 'love':
        return Colors.red;

      case 'wow':
        return Colors.orange;

      case 'sad':
        return Colors.amber;

      case 'angry':
        return Colors.deepOrange;

      case 'haha':
        return Colors.pink;

      case 'polti':
        return Colors.yellow;

      default:
        return Colors.grey;
    }
  }
}
