import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/main.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Current Queue", 
      child: StreamBuilder(
        stream: audio_handler.queue, 
        builder: (context, snapshot) {
          return ListView(
            children: [
              if (audio_handler.song_queue.isEmpty) Card(
                child: ListTile(
                  title: Text("No Song In Queue.  :("),
                )
              ),
              ...audio_handler.song_queue.asMap().entries.map((entry) => 
                Card(
                  child: ListTile(
                    leading: Text((entry.key+1).toString()),
                    title: Text(entry.value.song_name),
                  )
                )
              )
            ],
          );
        }
      ),
    );
  }
}