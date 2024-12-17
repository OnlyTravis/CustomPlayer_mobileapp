import 'package:flutter/material.dart';

import 'package:song_player/code/audio_handler.dart';

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

        return 
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