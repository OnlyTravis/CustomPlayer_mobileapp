import 'package:flutter/material.dart';
import 'package:song_player/code/audio_handler.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {

  Future<void> button_onPlaySong(int index) async {
    if (audio_handler.current_queue_index == index) return;
    await audio_handler.skipToIndex(index);
  }

  @override
  void initState() {
    audio_handler.queue.listen((_) {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Current Queue", 
      page: Pages.queuePage,
      child: ListView(
        children: [
          if (audio_handler.song_queue.isEmpty) AppCard(
            child: ListTile(
              title: Text("No Song In Queue.  :("),
            )
          ),
          ...audio_handler.song_queue.asMap().entries.map((entry) => 
            SongCard(entry.value, entry.key)
          )
        ],
      ),
    );
  }

  Widget SongCard(Song song, int index) {
    return GestureDetector(
      onTap: () => button_onPlaySong(index),
      child: AppCard(
        color: (audio_handler.current_queue_index == index)?Theme.of(context).colorScheme.secondaryContainer:null,
        child: ListTile(
          leading: Wrap(
            children: [
              Text((index+1).toString()),
              Icon(song.is_video?Icons.video_file:Icons.audio_file)
            ],
          ),
          title: Text(song.song_name),
          trailing: Wrap(
            children: [
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: () => audio_handler.removeQueueItem_(index), 
                  icon: Icon(Icons.delete)
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: (index == 0)?null:() => audio_handler.moveQueueItem(index, index-1), 
                  color: (index == 0)?const Color.fromARGB(101, 66, 66, 66):null,
                  icon: Icon(Icons.arrow_upward)
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: (index == audio_handler.song_queue.length-1)?null:() => audio_handler.moveQueueItem(index, index+1), 
                  color: (index == audio_handler.song_queue.length-1)?const Color.fromARGB(101, 66, 66, 66):null,
                  icon: Icon(Icons.arrow_downward)
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}