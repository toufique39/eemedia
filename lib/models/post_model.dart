class PostModel {
  final String id;
  final String userName;
  final String title;
  final String content;
  final String? description;
  final String imageUrl;
  final String VideoUrl;
  final String type; // "funny" | "educational"

  PostModel({
    required this.id,
    required this.userName,
    required this.title,
    required this.content,
    required this.description,
    required this.imageUrl,
    required this.VideoUrl,
    required this.type,
  });
}
