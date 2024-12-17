import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:song_player/code/permission.dart';

late MusicHandler audio_handler;

void initAudioHandler() {
  audio_handler = MusicHandler();
}

class MusicHandler extends BaseAudioHandler with SeekHandler {
  String music_folder_path = "";
  List<String> song_file_list = [];
  
  MusicHandler() {
    initSongList();
  }

  Future<void> initSongList() async {
    // 1. Get Permission for song files
    if (!await requestPermission(Permission.manageExternalStorage)) return;

    // 2. Set "Music" folder directory
    String path = (await getExternalStorageDirectory())?.path ?? "";
    if (path == "") return;

    List<String> arr = path.split("/"); 
    String folder_path = "";
    for (int i = 1; i < arr.length; i++) {
      if (arr[i] == "Android") break;
      folder_path += "/${arr[i]}";
    }
    folder_path += "/Music";
    music_folder_path = folder_path;

    // 3. Fetch files inside the folder
    List file_list = Directory(folder_path).listSync(recursive: true);
    print("{}][][][][][][][][]}");
    print(file_list);
    print("{}][][][][][][][][]}");
    
  }

  List<String> getSongListRaw() {
    return song_file_list;
  }
}