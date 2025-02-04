import 'dart:async';

import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FullScreenVideo extends StatefulWidget {
  const FullScreenVideo({super.key});
  
  @override 
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  late final StreamSubscription streamSubscription;
  bool is_rotated = false;

  @override
  void initState() {
    streamSubscription = audio_handler.queue.listen((queue) {
      if (mounted) setState(() {});
    });
    WakelockPlus.enable();

    super.initState();
  }
  @override
  void dispose() {
    streamSubscription.cancel();
    WakelockPlus.enable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            RotatedBox(
              quarterTurns: is_rotated?1:0,
              child: Center(
                child: audio_handler.is_playing_video ? AspectRatio(
                    aspectRatio: audio_handler.video_controller.value.aspectRatio,
                    child: VideoPlayer(audio_handler.video_controller),
                ) : AspectRatio(
                  aspectRatio: 4/3,
                  child: Container(
                    color: const Color.fromARGB(255, 86, 86, 86),
                    child: const Center(
                      child: Icon(
                        Icons.music_note,
                        size: 128,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    is_rotated = !is_rotated;
                  });
                }, 
                icon: const Icon(Icons.rotate_90_degrees_ccw)
              ),
            )
          ],
        )
      ),
    );
  }
}