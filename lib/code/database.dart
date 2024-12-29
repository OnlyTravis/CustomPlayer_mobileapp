import 'dart:convert';

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
    (query_result["tag_id_list"] == null)?[]:jsonDecode(query_result["tag_id_list"] as String) as List<int>,
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
    query_result["color_id"] as int,
    query_result["tag_id"] as int
  );
}
class Playlist {
  String playlist_name;
  List<int> song_id_list;
  int playlist_id;

  Playlist(this.playlist_name, this.song_id_list, this.playlist_id);

  Playlist.fromMap(Map<String, Object?> query_result): this(
    query_result["playlist_name"] as String,
    (query_result["song_id_list"] == null)?[]:jsonDecode(query_result["song_id_list"] as String) as List<int>,
    query_result["playlist_id"] as int
  );
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
        tag_list_json TEXT,
        author TEXT,
        song_id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Tags (
        tag_name TEXT UNIQUE,
        tag_count INTEGER,
        color_id INTEGER,
        tag_id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Playlists (
        playlist_name TEXT UNIQUE,
        song_id_list_json TEXT,
        playlist_id INTEGER PRIMARY KEY AUTOINCREMENT
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
        SET tag_id_list = '${jsonEncode(song.tag_id_list)}'
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
        SET tag_id_list = '${jsonEncode(song.tag_id_list)}'
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

  Future<bool> createPlaylist(String playlist_name, List<int> song_id_list) async {
    playlist_name = preventSqlInjection(playlist_name);  
    try {
      await db.rawInsert('''
        INSERT INTO Playlists (playlist_name, song_id_list_json)
        VALUES ('$playlist_name', '${jsonEncode(song_id_list)}')
      ''');
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
        SET song_id_list = '${jsonEncode(playlist.song_id_list)}'
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
        SET song_id_list = '${jsonEncode(playlist.song_id_list)}'
        WHERE playlist_id = $playlist_id
      ''');
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<Song> getSongFromPath(String path) async {
    path = path.replaceAll("'", "''");
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Songs where song_path = '$path'
      ''');
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
