import 'package:flutter/material.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Reel')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Implement sharing functionality here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reel shared successfully!')),
            );
          },
          child: const Text('Share Reel'),
        ),
      ),
    );
  }
}
