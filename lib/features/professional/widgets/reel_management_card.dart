import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReelManagementCard extends StatelessWidget {
  final String reelId;
  final Map<String, dynamic> reelData;

  const ReelManagementCard({
    super.key,
    required this.reelId,
    required this.reelData,
  });

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";

    final date = timestamp.toDate();

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = reelData["thumbnailUrl"] ?? "";
    final category = reelData["category"] ?? "Unknown";
    final subCategory = reelData["subcategory"] ?? "";
    final views = reelData["views"] ?? 0;
    final likes = reelData["likesCount"] ?? 0;
    final comments = reelData["commentsCount"] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: thumbnail.isNotEmpty
                  ? Image.network(
                      thumbnail,
                      width: 90,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 90,
                      height: 120,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.video_library),
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(subCategory),

                  const SizedBox(height: 8),

                  Text("Uploaded : ${formatDate(reelData["createdAt"])}"),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye, size: 18),

                      const SizedBox(width: 4),

                      Text("$views"),

                      const SizedBox(width: 15),

                      const Icon(Icons.favorite, color: Colors.red, size: 18),

                      const SizedBox(width: 4),

                      Text("$likes"),

                      const SizedBox(width: 15),

                      const Icon(Icons.comment, size: 18),

                      const SizedBox(width: 4),

                      Text("$comments"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
