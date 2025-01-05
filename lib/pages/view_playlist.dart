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

  Future<void> updateSongList() async {
    final List<Song> tmp_list = await db.getAllSongsFromPlaylist(playlist, SortingStyle.nameAsc);
    setState(() {
      song_list = tmp_list;
    });
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
            pageBuilder: (context, animation1, animation2) => PlaylistPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (_) => false
        );
      }
    }, () => {});
  }

  @override
  void initState() {
    playlist = widget.playlist;
    updateSongList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigationWrap(
      page_name: "Viewing Playlist", 
      padding: EdgeInsets.all(8),
      child: ListView(
        children: [
          InfoTable(),
          SongList(),
          ActionBar(),
        ],
      ),
    );
  }

  Widget SongList() {
    return AppCard(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Songs : ",
              textScaler: TextScaler.linear(1.5),
            ),
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
      child: Table(
        columnWidths: {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth()
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          InfoRow("Name", playlist.playlist_name, true),
          InfoRow("Count", playlist.song_id_list.length.toString(), false),
          InfoRow("Type", playlist.is_filtered_playlist?"Filtered Playlist":"Regular Playlist", false),
          InfoRow("id", playlist.playlist_id.toString(), false),
        ],
      ),
    );
  }
  TableRow InfoRow(String title, String value, bool editable) {
    return TableRow(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          child: Text(
            "$title: ", 
            textAlign: TextAlign.right,
            textScaler: TextScaler.linear(1.5),
          ),
        ),
        Container(
          padding: EdgeInsets.all(6),
          child: Text(
            value, 
            textScaler: TextScaler.linear(1.5)
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