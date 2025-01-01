import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideo extends StatefulWidget {
  const FullScreenVideo({super.key});
  
  @override 
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: audio_handler.is_playing_video
            ? AspectRatio(
                aspectRatio: audio_handler.video_controller.value.aspectRatio,
                child: VideoPlayer(audio_handler.video_controller),
              )
            : AspectRatio(
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
    );
  }
}