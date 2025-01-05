import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/settings_manager.dart';
import 'package:song_player/pages/fullscreen.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';
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
      MaterialPageRoute(builder: (context) => const FullScreenVideo())
    );
  }

  void button_changePlayMode() {
    switch (audio_handler.playing_mode) {
      case PlayingMode.forward: audio_handler.changePlayMode(PlayingMode.loopCurrent); break;
      case PlayingMode.loopCurrent: audio_handler.changePlayMode(PlayingMode.loopQueue); break;
      case PlayingMode.loopQueue: audio_handler.changePlayMode(PlayingMode.forward); break;
    }
    setState(() {});
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
      page: Pages.playerPage,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _mediaPlayer(),
              _mediaNameBar(),
              _mediaProgressBar(),
              _mediaControlBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaPlayer() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(settings_manager.getSetting(Settings.containerOpacity)),
          borderRadius: const BorderRadius.all(Radius.circular(12))
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
                const SizedBox(height: double.infinity,),
                IconButton(
                  onPressed: button_toFullScreen, 
                  icon: const Icon(Icons.fullscreen)
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: audio_handler.skipToPrevious, 
                    icon: const Icon(Icons.skip_previous),
                  ),
                  IconButton(
                    onPressed: is_playing?audio_handler.pause: audio_handler.play, 
                    icon: Icon(is_playing?Icons.pause : Icons.play_arrow),
                  ),
                  IconButton(
                    onPressed: audio_handler.skipToNext, 
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _mediaPlayModeButton(),
              )
            ],
          ),
        );
      }
    );
  }
  Widget _mediaPlayModeButton() {
    String text;
    IconData icon;

    switch (audio_handler.playing_mode) {
      case PlayingMode.forward: 
        text = "Forward";
        icon = Icons.forward;
        break;
      case PlayingMode.loopCurrent: 
        text = "Loop Current";
        icon = Icons.loop;
        break;
      case PlayingMode.loopQueue: 
        text = "Loop Queue";
        icon = Icons.loop;
        break;
    }

    return TextButton(
      onPressed: button_changePlayMode, 
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(10))
        ),
        padding: const EdgeInsets.all(6),
        child: Wrap(
          children: [
            Icon(icon),
            Text(text)
          ],
        ),
      ),
    );
  }
}