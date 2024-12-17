import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:song_player/code/permission.dart';

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  List<String> song_file_list = [];


  @override
  void initState() {
    requestPermission(Permission.manageExternalStorage);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text("Song List"),
      ),
    );
  }
}