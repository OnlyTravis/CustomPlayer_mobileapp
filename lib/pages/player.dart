import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/main.dart';
import 'package:song_player/pages/fullscreen.dart';
import 'package:video_player/video_player.dart';

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

  void button_toFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FullScreenVideo())
    );
  }

  @override
  void initState() {
    audio_handler.queue.listen((queue) {
      if (mounted) setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Audio Player", 
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mediaPlayer(),
            _mediaNameBar(),
            _mediaProgressBar(),
            _mediaControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _mediaPlayer() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.all(Radius.circular(12))
        ),
        child: Stack(
          children: [
            Center(
              child: audio_handler.is_playing_video
                ? AspectRatio(
                    aspectRatio: audio_handler.video_controller.value.aspectRatio,
                    child: VideoPlayer(audio_handler.video_controller),
                  )
                : Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.secondaryFixedDim,
                    size: 128,
                  ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: double.infinity,),
                IconButton(
                  onPressed: button_toFullScreen, 
                  icon: Icon(Icons.fullscreen)
                )
              ],
            ),
          ],
        )
      ),
    );
  }

  Widget _mediaNameBar() {
    return StreamBuilder(
      stream: audio_handler.mediaItem, 
      builder: (context, snapshot) {
        String song_title = (snapshot.data?.title != null)?"Playing : ${snapshot.data?.title}":"No Song In Queue";
        return Text(song_title);
      }
    );
  }

  Widget _mediaProgressBar() {
    return StreamBuilder<MediaState>(
      stream: audio_handler.mediaStateStream,
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
              onPressed: audio_handler.skipToPrevious, 
              icon: Icon(Icons.skip_previous),
            ),
            IconButton(
              onPressed: is_playing?audio_handler.pause: audio_handler.play, 
              icon: Icon(is_playing?Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              onPressed: audio_handler.skipToNext, 
              icon: Icon(Icons.skip_next),
            ),
          ],
        );
      }
    );
  }
}