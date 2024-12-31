import 'dart:convert';

import 'package:song_player/pages/playlist.dart';
import 'package:sqflite/sqflite.dart';

late DatabaseHandler db;

class Song {
  String song_name;
  String song_path;
  List<int> tag_id_list;
  String? author;
  int song_id;

  Song(this.song_name, this.song_path, this.tag_id_list, this.author, this.song_id);

  Song.fromMap(Map<String, Object?> query_result): this(
    query_result["song_name"] as String,
    query_result["song_path"] as String,
    (query_result["tag_id_list_json"] == null)?[]:jsonDecode(query_result["tag_id_list_json"] as String) as List<int>,
    query_result["author"] as String?,
    query_result["song_id"] as int
  );
}
class Tag {
  String tag_name;
  int tag_count;
  int tag_color_id;
  int tag_id;

  Tag(this.tag_name, this.tag_count, this.tag_color_id, this.tag_id);

  Tag.fromMap(Map<String, Object?> query_result): this(
    query_result["tag_name"] as String,
    query_result["tag_count"] as int,
    query_result["tag_color_id"] as int,
    query_result["tag_id"] as int
  );
}
class Playlist {
  String playlist_name;
  int playlist_id;
  List<int> song_id_list;
  bool is_filtered_playlist;
  List<List<ConditionInput>> condition_list;
  List<int> outer_operator_list;
  List<List<int>> inner_operator_list;

  Playlist(this.playlist_name, this.playlist_id, this.song_id_list, this.is_filtered_playlist, this.condition_list, this.outer_operator_list, this.inner_operator_list);

  Playlist.fromMap(Map<String, Object?> query_result): this(
    query_result["playlist_name"] as String,
    query_result["playlist_id"] as int,
    (query_result["song_id_list_json"] == null)?[]:jsonDecode(query_result["song_id_list"] as String) as List<int>,
    query_result["is_filtered_playlist"] as bool,
    (query_result["condition_list_json"] == null)?[]:jsonDecode(query_result["condition_list"] as String) as List<List<ConditionInput>>,
    (query_result["outer_operator_list_json"] == null)?[]:jsonDecode(query_result["outer_operator_list"] as String) as List<int>,
    (query_result["inner_operator_list_json"] == null)?[]:jsonDecode(query_result["inner_operator_list"] as String) as List<List<int>>
  );
}

enum SortingStyle {
  none,
  nameAsc,
  nameDesc
}

Future<void> initDatabase() async {
  db = DatabaseHandler();
  await db.initDatabase();
}

class DatabaseHandler {
  late Database db;

  Future<void> initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/Song_Player.db';
    db = await openDatabase(
      path,
      version: 1,
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Songs (
        song_name TEXT,
        song_path TEXT UNIQUE,
        tag_id_list_json TEXT,
        author TEXT,
        song_id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Tags (
        tag_name TEXT UNIQUE,
        tag_count INTEGER,
        tag_color_id INTEGER,
        tag_id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Playlists (
        playlist_name TEXT UNIQUE,
        playlist_id INTEGER PRIMARY KEY AUTOINCREMENT,
        is_filtered_playlist INTEGER NOT NULL,
        song_id_list_json TEXT,
        condition_list_json TEXT,
        outer_operation_list_json TEXT,
        inner_operation_list_json TEXT
      )
    ''');
  }

  String preventSqlInjection(String str_input) {
    return str_input.replaceAll("'", "''");
  }
  String toFileName(String file_path) {
    List<String> tmp = file_path.split("/").last.split(".");
    tmp.removeLast();
    return tmp.join(".");
  }
  Future<bool> refreshFilteredPlaylist(int playlist_id) async {
    // 1. Get playlist record & check if it is a filtered playlist
    final result_1 = await db.rawQuery('''
      SELECT * FROM Playlists WHERE playlist_id = $playlist_id
    ''');
    final Playlist playlist = Playlist.fromMap(result_1.first);
    if (!playlist.is_filtered_playlist) return false;

    // 2. Match conditions for all songs
    final List<int> song_id_list = []; 
    final List<Song> song_list = await getAllSong(SortingStyle.nameAsc);
    for (final song in song_list) {
      bool current = matchConditionSet(song, playlist.condition_list[0], playlist.inner_operator_list[0]);
      for (int i = 1; i < playlist.condition_list.length; i++) {
        switch (playlist.outer_operator_list[i-1]) {
          case 0: current = current && matchConditionSet(song, playlist.condition_list[i], playlist.inner_operator_list[i]); break;// And
          case 1: current = current || matchConditionSet(song, playlist.condition_list[i], playlist.inner_operator_list[i]); break;
        }
      }
      if (current) song_id_list.add(song.song_id);
    }

    // 3. Update playlist
    await db.rawUpdate('''
      UPDATE Playlists 
      SET song_id_list_json = '${jsonEncode(song_id_list)}'
      WHERE playlist_id = $playlist_id
    ''');
    print("%&*#&%#*&%#*%#&*%&%*#%**%#&%*#%&");
    print(song_id_list);    
    print("%&*#&%#*&%#*%#&*%&%*#%**%#&%*#%&");

    return true;
  }
  bool matchConditionSet(Song song, List<ConditionInput> condition_list, List<int> operators) {
    bool current = matchCondition(song, condition_list[0]);
    for (int i = 1; i < condition_list.length; i++) {
      switch (operators[i-1]) {
        case 0: current = current && matchCondition(song, condition_list[i]); break;// And
        case 1: current = current || matchCondition(song, condition_list[i]); break;
      }
    }
    return current;
  }
  bool matchCondition(Song song, ConditionInput condition) {
    switch (conditions[condition.condition].name) {
      case "hasTag":
        return song.tag_id_list.contains(condition.value);
      case "withoutTag":
        return !song.tag_id_list.contains(condition.value);
      default:  
        print("Somthings went wrong in 'matchCondition' in database.dart");
        return false;
    }
  }

  Future<Song> addSong(String path) async {
    final String song_name = toFileName(path);
    await db.rawInsert('''
      INSERT INTO Songs (song_name, song_path)
      VALUES ('$song_name', '$path');
    ''');
    final result = await db.rawQuery('''
      SELECT * FROM Songs where song_path = '$path'
    ''');
    return Song.fromMap(result.first);
  }
  Future<bool> changeSongName(int song_id, String song_name) async {
    song_name = preventSqlInjection(song_name);

    await db.rawUpdate('''
      UPDATE Songs
      SET song_name = '$song_name'
      WHERE song_id = $song_id 
    ''');

    return true;
  }
  Future<bool> changeAuthor(int song_id, String author) async {
    author = preventSqlInjection(author);

    await db.rawUpdate('''
      UPDATE Songs
      SET author = '$author'
      WHERE song_id = $song_id 
    ''');

    return true;
  }
  Future<bool> addTagToSong(int song_id, int tag_id) async {
    try {
      // 1. Fetch Song's tag list & add tag to it
      final result = await db.rawQuery('''
        SELECT * FROM Songs
        WHERE song_id = $song_id 
      ''');
      final Song song = Song.fromMap(result.first);
      song.tag_id_list.add(tag_id);

      // 2. Update Song's record's json text
      await db.rawUpdate('''
        UPDATE Songs
        SET tag_id_list_json = '${jsonEncode(song.tag_id_list)}'
        WHERE song_id = $song_id
      ''');

      // 3. Update Tag's count
      await db.rawUpdate('''
        UPDATE Tags
        SET tag_count = tag_count+1
        WHERE tag_id = $tag_id 
      ''');
      return true; 
    } catch (err) {
      return false;
    }
  }
  Future<bool> removeTagFromSong(int song_id, int tag_id) async {
    try {
      // 1. Fetch Song's tag list & remove tag from it
      final result = await db.rawQuery('''
        SELECT * FROM Songs
        WHERE song_id = $song_id 
      ''');
      final Song song = Song.fromMap(result.first);
      if (!song.tag_id_list.remove(tag_id)) return false;

      // 2. Update Song's record's json text
      await db.rawUpdate('''
        UPDATE Songs
        SET tag_id_list_json = '${jsonEncode(song.tag_id_list)}'
        WHERE song_id = $song_id
      ''');

      // 3. Update Tag's count
      await db.rawUpdate('''
        UPDATE Tags
        SET tag_count = tag_count-1
        WHERE tag_id = $tag_id 
      ''');
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> createTag(String tag_name, int tag_color_id) async {
    tag_name = preventSqlInjection(tag_name);

    await db.rawInsert('''
      INSERT INTO Tags (tag_name, tag_count, tag_color_id)
      VALUES ('$tag_name', 0, $tag_color_id);
    ''');

    return true;
  }
  Future<bool> deleteTag(int tag_id) async {
    try {
      await db.rawDelete('''
        DELETE FROM Tags WHERE tag_id = $tag_id;
      ''');

      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> createRegularPlaylist(String playlist_name, List<int> song_id_list) async {
    playlist_name = preventSqlInjection(playlist_name);  
    try {
      await db.rawInsert('''
        INSERT INTO Playlists (playlist_name, is_filtered_playlist, song_id_list_json)
        VALUES ('$playlist_name', 0, '${jsonEncode(song_id_list)}')
      ''');
      return true;
    } catch (err) {
      return false;
    }
  }
  Future<bool> createFilterPlaylist(String playlist_name, List<List<ConditionInput>> condition_list, List<int> outer_condition_list, List<List<int>> inner_condition_list) async {
    playlist_name = preventSqlInjection(playlist_name);  
    try {
      int row_id = await db.rawInsert('''
        INSERT INTO Playlists (playlist_name, is_filtered_playlist, condition_list_json, outer_operation_list_json, inner_operation_list_json)
        VALUES ('$playlist_name', 1, '${jsonEncode(condition_list)}', '${jsonEncode(outer_condition_list)}', '${jsonEncode(inner_condition_list)}')
      ''');
      await refreshFilteredPlaylist(row_id);

      return true;
    } catch (err) {
      return false;
    }
  }
  Future<bool> deletePlaylist(int playlist_id) async { 
    try {
      await db.rawDelete('''
        DELETE FROM Playlists WHERE playlist_id = $playlist_id
      ''');
      return true;
    } catch (err) {
      return false;
    }
  }
  Future<bool> addSongToPlaylist(int playlist_id, int song_id) async {
    try {
      // 1. Fetch Playlist's record & Update its song_id_list
      final result = await db.rawQuery('''
        SELECT * FROM Playlists WHERE playlist_id = $playlist_id
      ''');
      final Playlist playlist = Playlist.fromMap(result.first);
      playlist.song_id_list.add(song_id);

      // 2. Update the Playlist's record
      await db.rawUpdate('''
        UPDATE Playlists
        SET song_id_list_json = '${jsonEncode(playlist.song_id_list)}'
        WHERE playlist_id = $playlist_id
      ''');
      return true;
    } catch (err) {
      return false;
    }
  }
  Future<bool> removeSongFromPlaylist(int playlist_id, int song_id) async {
    try {
      // 1. Fetch Playlist's record & Update its song_id_list
      final result = await db.rawQuery('''
        SELECT * FROM Playlists WHERE playlist_id = $playlist_id
      ''');
      final Playlist playlist = Playlist.fromMap(result.first);
      if (!playlist.song_id_list.remove(song_id)) return false;

      // 2. Update the Playlist's record
      await db.rawUpdate('''
        UPDATE Playlists
        SET song_id_list_json = '${jsonEncode(playlist.song_id_list)}'
        WHERE playlist_id = $playlist_id
      ''');
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<List<Song>> getAllSong(SortingStyle sort) async {
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Songs
      ''');
      final List<Song> song_list = result.map((song_map) => Song.fromMap(song_map)).toList();
      switch (sort) {
        case SortingStyle.none: return song_list;
        case SortingStyle.nameAsc: return song_list..sort((a, b) => a.song_name.compareTo(b.song_name));
        case SortingStyle.nameDesc: return song_list..sort((a, b) => b.song_name.compareTo(a.song_name));
      }
    } catch (err) {
      return [];
    }
  }
  Future<Song> getSongFromPath(String path) async {
    path = preventSqlInjection(path);
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Songs where song_path = '$path'
      ''');
      print(result);
      return Song.fromMap(result.first);
    } catch (err) {
      return await addSong(path);
    }
  }
  
  Future<List<Tag>> getAllTags() async {
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Tags
      ''');
      return result.map((res) => Tag.fromMap(res)).toList();
    } catch (err) {
      return [];
    }
  }
  Future<List<Tag>> getTagsFromSongId(int song_id) async {
    try {
      // 1. Fetch Song's record
      final result_1 = await db.rawQuery('''
        SELECT * FROM Songs where song_id = $song_id
      ''');
      final Song song = Song.fromMap(result_1.first);
      print(result_1);
      print(song);
      
      // 2. Iterate through tag_id_list and fetch each individual record
      final List<Tag> tag_list = [];
      for (final tag_id in song.tag_id_list) {
        final result_2 = await db.rawQuery('''
          SELECT * FROM Tags where tag_id = $tag_id
        ''');
        tag_list.add(Tag.fromMap(result_2.first));
      }
      return tag_list;
    } catch (err) {
      return [];
    }
  }
}
