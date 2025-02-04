import 'package:flutter/material.dart';
import 'package:song_player/code/database.dart';
import 'package:song_player/code/utils.dart';
import 'package:song_player/pages/playlist.dart';
import 'package:song_player/widgets/AppNavigationWrap.dart';
import 'package:song_player/widgets/Card.dart';

class ViewPlaylistPage extends StatefulWidget {
  final Playlist playlist;
  const ViewPlaylistPage({super.key, required this.playlist});

  @override
  State<StatefulWidget> createState() => _ViewPlaylistPageState();
}
class _ViewPlaylistPageState extends State<ViewPlaylistPage> {
  late Playlist playlist;
  List<Song> song_list = [];

  TextEditingController playlist_name_controller = TextEditingController();
  bool is_editing = false;
  bool need_update = false;

  Future<void> updateSongList() async {
    final List<Song> tmp_list = await db.getAllSongsFromPlaylist(playlist, SortingStyle.nameAsc);
    setState(() {
      song_list = tmp_list;
    });
  }

  @override
  void initState() {
    playlist = widget.playlist;
    playlist_name_controller.text = playlist.playlist_name;

    updateSongList();
    super.initState();
  }

  Future<void> button_onUpdatePlaylist() async {
    await db.refreshFilteredPlaylist(playlist.playlist_id);
    final Playlist tmp_playlist = await db.getPlaylistFromId(playlist.playlist_id);
    playlist = tmp_playlist;
    await updateSongList();
    if (mounted) alert(context, "Playlist Refreshed !", duration: 1);
  }
  void button_onDeletePlaylist() {
    confirm(context, "Confirm Deletion", "Are you sure you want to delete this playlist?", () async {
      await db.deletePlaylist(playlist.playlist_id);
      if (mounted) alert(context, "Playlist \"${playlist.playlist_name}\" has been removed");
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => const PlaylistPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (_) => false
        );
      }
    }, () => {});
  }
  void button_toggleEditMode() {
    setState(() {
      is_editing = !is_editing;
    });
  }
  Future<void> button_applyChange() async {
    if (playlist_name_controller.text.isEmpty) {
      alert(context, "Please enter a valid playlist name.");
      return;
    }

    if (playlist_name_controller.text != playlist.playlist_name) {
      await db.renamePlaylist(playlist.playlist_id, playlist_name_controller.text);
    }

    setState(() {
      playlist.playlist_name = playlist_name_controller.text;
      need_update = false;
      is_editing = false;
    });
  }
  void button_resetChange() {
    playlist_name_controller.text = playlist.playlist_name;
    setState(() {
      need_update = false;
      is_editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      pageName: "Viewing Playlist",
      pageIcon: const Icon(Icons.playlist_add),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: [
              InfoTable(),
              SongList(),
              ActionBar(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: button_toggleEditMode,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget SongList() {
    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Songs : ", textScaler: TextScaler.linear(1.5)),
            ...song_list.map((song) => DisplaySong(song))
          ],
        )
      ),
    );
  }
  Widget DisplaySong(Song song) {
    return Text("${song.song_name} - ${song.author}");
  }
 
  Widget InfoTable() {
    return AppCard(
      child: Column(
        children: [
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth()
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              InfoRow("Name", playlist.playlist_name, editable: true, controller: playlist_name_controller),
              InfoRow("Count", playlist.song_id_list.length.toString()),
              InfoRow("Type", playlist.is_filtered_playlist ? "Filtered Playlist" : "Regular Playlist"),
              InfoRow("id", playlist.playlist_id.toString()),
            ],
          ),
          if (need_update) Row(
            children: [
              TextButton(
                onPressed: button_applyChange, 
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Wrap(
                      children: [
                        Icon(Icons.update),
                        Text("Apply Changes")
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: button_resetChange, 
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Wrap(
                      children: [
                        Icon(Icons.cancel),
                        Text("Reset Changes")
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      )
    );
  }
  TableRow InfoRow(String title, String value, {bool editable = false, TextEditingController? controller}) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          child: Text(
            "$title: ", 
            textAlign: TextAlign.right,
            textScaler: const TextScaler.linear(1.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          child: (is_editing && editable)? 
            SizedBox(
              height: 40,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setState(() {
                    need_update = true;
                  });
                },
                controller: controller,
              ),
            ) : Text(
              value, 
              textScaler: const TextScaler.linear(1.5)
            ),
        ),
      ]
    );
  }

  Widget ActionBar() {
    return AppCard(
      child: Row(
        children: [
          if (playlist.is_filtered_playlist) TextButton(
            onPressed: button_onUpdatePlaylist, 
            child: const Text("Update Playlist"),
          ),
          TextButton(
            onPressed: button_onDeletePlaylist, 
            child: const Text("Delete Playlist"),
          )
        ],
      ),
    );
  }
}