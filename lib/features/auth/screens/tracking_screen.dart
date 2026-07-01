import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tracking_provider.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Tracking")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Fun Time: ${tracker.funTime} sec"),
            if (tracker.isBlocked)
              const Text(
                "⚠️ Funny content blocked! Educational mode active",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
