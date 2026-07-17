import 'dart:async';
import 'package:eemedia/features/auth/screens/comment_screen.dart';
import 'package:eemedia/features/home/widgets/reaction_helper.dart';
import 'package:eemedia/features/home/widgets/reaction_picker.dart';
import 'package:eemedia/providers/screen_time_provider.dart';
import 'package:eemedia/services/interaction_service.dart';
import 'package:eemedia/services/reaction_service.dart' as reaction_service;
import 'package:eemedia/services/screen_time_service.dart';
import 'package:eemedia/services/view_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

class ReelItem extends StatefulWidget {
  final Map<String, dynamic> reelData;
  final String reelId;
  final bool isActive;
  final VoidCallback? onLimitReached;

  const ReelItem({
    super.key,
    required this.reelId,
    required this.reelData,
    required this.isActive,
    this.onLimitReached,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _videoController;
  bool _viewSaved = false;
  Timer? _viewTimer;
  Timer? _watchTimer;
  bool isLoading = true;
  bool hasVideoError = false;
  bool _isDisposed = false;
  bool _watchInteractionSaved = false;
  int _watchedSeconds = 0;

  int commentsCount = 0;
  int sharesCount = 0;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    WidgetsBinding.instance.addObserver(this);

    commentsCount = widget.reelData['commentsCount'] ?? 0;
    sharesCount = widget.reelData['sharesCount'] ?? 0;

    if (widget.isActive) _initializeAndPlayVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("APP STATE = $state");

    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.isActive) {
          _player.play();
          _startWatchTimer();
        }

        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _player.pause();

        _pauseAndSaveWatchData();

        break;
    }
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;

    if (widget.isActive) {
      if (_player.state.playlist.medias.isEmpty) {
        _initializeAndPlayVideo();
      } else {
        _player.play();
        _startWatchTimer();
        _startViewTimer();
      }
    } else {
      _player.pause();
      _pauseAndSaveWatchData();
    }
  }

  Future<void> _initializeAndPlayVideo() async {
    if (_isDisposed) return;

    final videoUrl = widget.reelData['videoUrl']?.toString().trim() ?? '';

    debugPrint('=== VIDEO DEBUG ===');
    debugPrint('URL: $videoUrl');

    if (videoUrl.isEmpty || !videoUrl.startsWith('http')) {
      debugPrint('VIDEO URL MISSING → reel=${widget.reelId}');
      if (mounted)
        setState(() {
          hasVideoError = true;
          isLoading = false;
        });
      return;
    }

    try {
      await _player.open(Media(videoUrl), play: false);
      await _player.setPlaylistMode(PlaylistMode.loop);

      if (widget.isActive) {
        await _player.play();
        _startWatchTimer();
        _startViewTimer();
      }

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint('VIDEO ERROR → $e');
      if (mounted)
        setState(() {
          hasVideoError = true;
          isLoading = false;
        });
    }
  }

  void _startWatchTimer() {
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !widget.isActive) {
        timer.cancel();
        return;
      }
      if (_player.state.playing) _watchedSeconds++;
    });
  }

  void _startViewTimer() {
    _viewTimer?.cancel();

    _viewTimer = Timer(const Duration(seconds: 3), () async {
      if (_viewSaved) return;

      _viewSaved = true;

      final added = await ViewService.addView(reelId: widget.reelId);

      debugPrint("VIEW ADDED = $added");

      if (!added) return;

      await InteractionService.logInteraction(
        reelId: widget.reelId,

        eventType: "view",

        eventValue: 1,

        finalCategory:
            widget.reelData["finalCategory"] ??
            widget.reelData["userCategory"] ??
            "Other",

        subCategory: widget.reelData["subCategory"] ?? "",
      );

      debugPrint("VIEW INTERACTION SAVED");
    });
  }

  void _pauseAndSaveWatchData() {
    _watchTimer?.cancel();
    _viewTimer?.cancel();
    _saveWatchData();
  }

  void _saveWatchData() {
    if (_watchInteractionSaved || _watchedSeconds <= 0) return;

    final secondsToSave = _watchedSeconds;

    final category =
        widget.reelData['finalCategory']?.toString() ??
        widget.reelData['userCategory']?.toString() ??
        'Other';
    final subCategory = widget.reelData['subCategory']?.toString() ?? '';
    final reelId = widget.reelId;
    debugPrint(widget.reelData.toString());
    _watchedSeconds = 0;
    _watchInteractionSaved = true;

    if (mounted) {
      final provider = context.read<ScreenTimeProvider>();
      provider
          .addWatchTime(category: category, watchedSeconds: secondsToSave)
          .then((_) {
            if (provider.limitReached) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Educational Mode Activated")),
                );
              }
            }
            debugPrint("LIMIT REACHED = ${provider.limitReached}");
            debugPrint("SECONDS = ${provider.entertainmentSeconds}");
          });
    } else {
      ScreenTimeService.addWatchTime(
        finalcategory: category,
        watchedSeconds: secondsToSave,
      ).catchError((e) => debugPrint('Screen time error: $e'));
    }

    InteractionService.logInteraction(
      reelId: reelId,
      eventType: 'watch',
      eventValue: secondsToSave,
      finalCategory: category,
      subCategory: subCategory,
    ).catchError((e) => debugPrint('Interaction error: $e'));

    debugPrint('WATCH SAVED → reel=$reelId, seconds=$secondsToSave');
  }

  Future<void> toggleReaction({
    required String collection,
    required String documentId,
    required dynamic reaction,
  }) async {
    try {
      await reaction_service.toggleReaction(
        collection: collection,
        documentId: documentId,
        reaction: reaction,
      );
    } catch (e) {
      debugPrint('Reaction error: $e');
    }
  }

  String formatViews(int views) {
    if (views >= 1000000) {
      return "${(views / 1000000).toStringAsFixed(1)}M";
    }

    if (views >= 1000) {
      return "${(views / 1000).toStringAsFixed(1)}K";
    }

    return views.toString();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _isDisposed = true;

    _watchTimer?.cancel();

    _saveWatchData();

    _player.pause();

    _player.dispose();
    _viewTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final reactions = Map<String, dynamic>.from(
      widget.reelData["reactions"] ?? {},
    );
    final myReaction = reactions[currentUserId];
    final reactionCount = reactions.length;
    final postUser = widget.reelData['userData'] as Map<String, dynamic>? ?? {};
    final postUserName = postUser['name']?.toString() ?? 'Unknown User';
    final postUsername = postUser['username']?.toString() ?? '';
    final avatarUrl = postUser['imageUrl']?.toString() ?? '';

    if (hasVideoError) return const _VideoErrorView();

    if (isLoading) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            if (_player.state.playing) {
              _player.pause();

              _viewTimer?.cancel();
            } else {
              _player.play();

              _startViewTimer();
            }

            if (mounted) {
              setState(() {});
            }
          },
          child: Video(
            controller: _videoController,
            fit: BoxFit.cover,
            controls: NoVideoControls,
          ),
        ),

        StreamBuilder<bool>(
          stream: _player.stream.playing,
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            if (playing) return const SizedBox.shrink();
            return const Center(
              child: Icon(Icons.play_arrow, color: Colors.white54, size: 60),
            );
          },
        ),

        Positioned(
          left: 12,
          bottom: 100,
          width: MediaQuery.of(context).size.width * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  postUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  '@$postUsername',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              if ((widget.reelData['caption']?.toString() ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.reelData['caption'].toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),

        Positioned(
          right: 12,
          bottom: 90,
          child: Column(
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    color: Colors.white,
                    size: 30,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "${formatViews(widget.reelData["views"] ?? 0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              IconButton(
                onPressed: () async {
                  await toggleReaction(
                    collection: "reels",
                    documentId: widget.reelId,
                    reaction: "like",
                  );
                  await InteractionService.logReactionInteraction(
                    reelId: widget.reelId,
                    reaction: "like",
                    finalCategory:
                        widget.reelData["finalCategory"] ??
                        widget.reelData["userCategory"] ??
                        "Other",
                    subCategory: widget.reelData["subCategory"] ?? "",
                  );
                  if (!mounted) return;
                  setState(() {});
                },

                icon: Text(
                  ReactionHelper.getReactionEmoji(myReaction),

                  style: const TextStyle(fontSize: 30),
                ),

                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (_) => ReactionPicker(
                      onReactionSelected: (reaction) async {
                        await toggleReaction(
                          collection: 'reels',
                          documentId: widget.reelId,
                          reaction: reaction,
                        );

                        if (!mounted) return;
                        await InteractionService.logReactionInteraction(
                          reelId: widget.reelId,
                          reaction: reaction.toString(),
                          finalCategory:
                              widget.reelData['finalCategory']?.toString() ??
                              widget.reelData['userCategory']?.toString() ??
                              'Other',
                          subCategory:
                              widget.reelData['subCategory']?.toString() ?? '',
                        );
                      },
                    ),
                  );
                },
              ),

              Text(
                "$reactionCount",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                ReactionHelper.getReactionLabel(myReaction),
                style: TextStyle(
                  color: ReactionHelper.getReactionColor(myReaction),
                ),
              ),

              const SizedBox(height: 20),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    builder: (context) => CommentScreen(
                      collection: 'reels',
                      documentId: widget.reelId,
                    ),
                  );
                },
                icon: const Icon(Icons.comment, color: Colors.white, size: 32),
              ),
              Text("${widget.reelData["commentCount"] ?? 0}"),

              const SizedBox(height: 20),
              IconButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/share',
                  arguments: {
                    'reelId': widget.reelId,
                    'reelData': widget.reelData,
                  },
                ),
                icon: const Icon(Icons.share, color: Colors.white, size: 32),
              ),
              Text('$sharesCount', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),

        Positioned(
          left: MediaQuery.of(context).size.width * 0.05,
          top: 10,
          child: BackButton(
            color: Colors.white,
            onPressed: () {
              _player.pause();

              _pauseAndSaveWatchData();

              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}

class _VideoErrorView extends StatelessWidget {
  const _VideoErrorView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_file_outlined, color: Colors.white, size: 52),
              SizedBox(height: 12),
              Text(
                'This video cannot be played on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
