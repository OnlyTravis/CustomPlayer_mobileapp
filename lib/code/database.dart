import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

late DatabaseHandler db;

class Song {
  String song_name;
  String song_path;
  String? author;
  int song_id;

  Song(this.song_name, this.song_path, this.author, this.song_id);
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
        song_path TEXT,
        author TEXT,
        song_id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Tags (
        tag_name TEXT,
        tag_color_id INTEGER,
        tag_id INTEGER PRIMARY KEY
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Linkages (
        song_id INTEGER,
        tag_id INTEGER,
        PRIMARY KEY (song_id, tag_id)
      )
    ''');
  }

  bool detectSqlInjection(String str_input) {
    return str_input.contains('\'') || str_input.contains('"') || str_input.contains('\\');
  }
  String toFileName(String file_path) {
    List<String> tmp = file_path.split("/").last.split(".");
    tmp.removeLast();
    return tmp.join(".");
  }
  Song toSong(Map<String, Object?> query_result) {
    return Song(
      query_result["song_name"] as String,
      query_result["song_path"] as String,
      query_result["author"] as String?,
      query_result["song_id"] as int
    );
  }

  Future<bool> changeSongName(int song_id, String song_name) async {
    if (detectSqlInjection(song_name)) return false;

    await db.execute('''
      UPDATE Songs
      SET song_name = '$song_name'
      WHERE song_id = $song_id 
    ''');

    return true;
  }
  Future<bool> changeAuthor(int song_id, String author) async {
    if (detectSqlInjection(author)) return false;

    await db.execute('''
      UPDATE Songs
      SET author = '$author'
      WHERE song_id = $song_id 
    ''');

    return true;
  }
  Future<bool> addTagToSong(int song_id, int tag_id) async {
    await db.execute('''
      INSERT INTO Linkages (song_id, tag_id)
      VALUES ('$song_id', $tag_id);
    ''');
    return true;
  }
  Future<bool> removeTagFromSong(int song_id, int tag_id) async {
    await db.execute('''
      DELETE FROM Tags WHERE song_id = $song_id AND tag_id = $tag_id;
    ''');
    return true;
  }

  Future<bool> createTag(String tag_name, int tag_color_id) async {
    if (detectSqlInjection(tag_name)) return false;

    await db.execute('''
      INSERT INTO Tags (tag_name, tag_color_id)
      VALUES ('$tag_name', $tag_color_id);
    ''');

    return true;
  }
  Future<bool> deleteTag(int tag_id) async {
    await db.execute('''
      DELETE FROM Tags WHERE tag_id = $tag_id;
    ''');

    return true;
  }
  
  Future<Song> addSong(String path) async {
    final String song_name = toFileName(path);
    await db.execute('''
      INSERT INTO Songs (song_name, song_path)
      VALUES ('$song_name', '$path');
    ''');
    final result = await db.rawQuery('''
      SELECT * FROM Songs where song_path = '$path'
    ''');
    return toSong(result.first);
  }

  Future<Song> getSongFromPath(String path) async {
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Songs where song_path = '$path'
      ''');
      return toSong(result.first);
    } catch (err) {
      return await addSong(path);
    }
  }
}
