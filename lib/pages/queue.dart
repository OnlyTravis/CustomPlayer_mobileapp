import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text("Song List"),
      ),
      body: StreamBuilder(
        stream: audio_handler.queue, 
        builder: (context, snapshot) {
          final queue = snapshot.data ?? [];
          print(snapshot.data);

          return ListView(
            children: [...queue.asMap().entries.map((entry) => 
              Card(
                child: ListTile(
                  leading: Text((entry.key+1).toString()),
                  title: Text(entry.value.title),
                ))
              )
            ],
          );
        }
      )
    );
  }
}