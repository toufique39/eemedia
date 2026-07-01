import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (_) {
        Navigator.pop(context);
      },

      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        body: Hero(
          tag: imageUrl,

          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),

            minScale: PhotoViewComputedScale.contained,

            maxScale: PhotoViewComputedScale.covered * 4,
            enablePanAlways: true,
            enableRotation: false,
            backgroundDecoration: const BoxDecoration(color: Colors.black),

            loadingBuilder: (context, event) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },

            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
