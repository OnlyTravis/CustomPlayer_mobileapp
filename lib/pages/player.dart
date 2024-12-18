import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';

String toTimeFormat(Duration duration) {
  String negativeSign = duration.isNegative ? '-' : '';

  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  return "$negativeSign${duration.inHours > 0? "${twoDigits(duration.inHours)}:": ""}$twoDigitMinutes:$twoDigitSeconds";
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text("Audio Player"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mediaNameBar(),
            _mediaProgressBar(),
            _mediaControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _mediaNameBar() {
    return StreamBuilder(
      stream: audio_handler.mediaItem, 
      builder: (context, snapshot) {
        String song_title = snapshot.data?.title ?? "No Song In Queue";
        return Text(song_title);
      }
    );
  }

  Widget _mediaProgressBar() {
    return StreamBuilder<MediaState>(
      stream: mediaStateStream,
      builder: (context, snapshot) {
        final mediaState = snapshot.data;

        Duration duration = mediaState?.mediaItem?.duration ?? Duration.zero;
        Duration position = mediaState?.position ?? Duration.zero;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Slider(
              min: 0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.toDouble(), 
              onChanged: (new_value) {
                audio_handler.seek(Duration(seconds: new_value.toInt()));
              }
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(toTimeFormat(position)),
                  Text(toTimeFormat(duration)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mediaControlBar() {
    return StreamBuilder<bool>(
      stream: audio_handler.playbackState.map((state) => state.playing), 
      builder: (context, snapshot) {
        bool is_playing = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: is_playing?audio_handler.pause: audio_handler.play, 
              icon: Icon(is_playing?Icons.pause : Icons.play_arrow),
            ),
          ],
        );
      }
    );
  }
}