import 'dart:convert';
import 'dart:io';

import 'package:song_player/code/file_handler.dart';
import 'package:song_player/pages/playlist.dart';
import 'package:sqflite/sqflite.dart';

late DatabaseHandler db;

class Song {
  String song_name;
  String song_path;
  List<int> tag_id_list;
  String? author;
  double volume;
  bool is_video;
  int song_id;

  Song(this.song_name, this.song_path, this.tag_id_list, this.author, this.volume, this.is_video, this.song_id);

  Song.fromMap(Map<String, Object?> query_result): this(
    query_result["song_name"] as String,
    query_result["song_path"] as String,
    (query_result["tag_id_list_json"] == null)?[]:jsonDecode(query_result["tag_id_list_json"] as String).cast<int>(),
    query_result["author"].toString(),
    (query_result["volume"] == null)?1:query_result["volume"] as double,
    query_result["is_video"] == 1,
    query_result["song_id"] as int
  );

  @override
  String toString() {
    return "Song{song_name: $song_name, song_path: $song_path, tag_id_list: $tag_id_list, author: $author, volume: $volume, is_video: $is_video, song_id: $song_id}";
  }
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

  factory Playlist.fromMap(Map<String, Object?> query_result) {
    List<List<ConditionInput>> tmp_1 = [];
    if (query_result["condition_list_json"] != null) {
      final List<dynamic> decoded = jsonDecode(query_result["condition_list_json"] as String);
      for (int i = 0; i < decoded.length; i++) {
        tmp_1.add([]);
        for (int j = 0; j < decoded[i].length; j++) {
          tmp_1[i].add(ConditionInput(decoded[i][j][0], decoded[i][j][1]));
        }
      }
    }
    List<List<int>> tmp_2 = [];
    if (query_result["inner_operator_list_json"] != null) {
      final List<dynamic> decoded = jsonDecode(query_result["inner_operator_list_json"] as String);
      for (int i = 0; i < decoded.length; i++) {
        tmp_2.add([]);
        for (int j = 0; j < decoded[i].length; j++) {
          tmp_2[i].add(decoded[i][j]);
        }
      }
    }
    return Playlist(
      query_result["playlist_name"] as String,
      query_result["playlist_id"] as int,
      (query_result["song_id_list_json"] == null)?[]:jsonDecode(query_result["song_id_list_json"] as String).cast<int>(),
      query_result["is_filtered_playlist"] == 1,
      (query_result["condition_list_json"] == null)?[]:tmp_1,
      (query_result["outer_operator_list_json"] == null)?[]:jsonDecode(query_result["outer_operator_list_json"] as String).cast<int>(),
      (query_result["inner_operator_list_json"] == null)?[]:tmp_2
    );
  }
  
  @override
  String toString() {
    return 'Playlist{playlist_name:"$playlist_name", playlist_id:"$playlist_id", song_id_list:"$song_id_list"}';
  }
}

enum SortingStyle {
  none(sort_type : 0, is_asc : true),
  nameAsc(sort_type : 1, is_asc : true),
  nameDesc(sort_type : 1, is_asc : false),
  fileNameAsc(sort_type : 2, is_asc : true),
  fileNameDesc(sort_type : 2, is_asc : false);

  static int type_count = 3;
  final bool is_asc;
  final int sort_type;

  const SortingStyle({
    required this.is_asc,
    required this.sort_type
  });

  factory SortingStyle.fromValues(int sort_type, bool is_asc) {
    if (is_asc) {
      switch (sort_type) {
        case 0: return SortingStyle.none;
        case 1: return SortingStyle.nameAsc;
        case 2: return SortingStyle.fileNameAsc;
      }
    } else {
      switch (sort_type) {
        case 0: return SortingStyle.none;
        case 1: return SortingStyle.nameDesc;
        case 2: return SortingStyle.fileNameDesc;
      }
    }
    return SortingStyle.none;
  }

  String get type_name {
    switch (sort_type) {
      case 0: return "None";
      case 1: return "Name";
      case 2: return "File Name";
      default: return "";
    }
  }
}

Future<void> initDatabase() async {
  db = DatabaseHandler();
  await db.initDatabase();
}

class DatabaseHandler {
  String database_path = "";
  late Database db;

  Future<void> initDatabase() async {
    final databaseFolderPath = await getDatabasesPath();
    database_path = '$databaseFolderPath/Song_Player.db';
    db = await openDatabase(
      database_path,
      version: 1,
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Songs (
        song_name TEXT,
        song_path TEXT UNIQUE,
        tag_id_list_json TEXT,
        author TEXT,
        volume REAL,
        is_video INTEGER NOT NULL,
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
        outer_operator_list_json TEXT,
        inner_operator_list_json TEXT
      )
    ''');
  }
  Future<void> addDefaultPlaylist() async {
    final result = await db.rawQuery('''
      SELECT COUNT() FROM Playlists
    ''');

    if (result.first["COUNT()"] == 0) {
      await createFilterPlaylist("All Songs", [], [], []);
    }
  }

  String preventSqlInjection(String str_input) {
    return str_input.replaceAll("'", "''");
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
    final List<Song> song_list = await getAllSongs(SortingStyle.nameAsc);
    for (final song in song_list) {
      if (playlist.condition_list.isEmpty) {
        song_id_list.add(song.song_id);
        continue;
      }

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
  Future<void> updateSongDatabase(List<FileEntity> entity_list) async {
    // 1. Remove deleted song files
    List<Song> song_list = await getAllSongs(SortingStyle.none);
    for (final Song song in song_list) {
      if (entity_list.indexWhere((entity) => entity.getFullPath() == song.song_path) == -1) {
        await db.rawDelete('''
          DELETE FROM Songs WHERE song_id = ${song.song_id}
        ''');
      }
    }

    // 2. Add New Songs to Database
    for (final entity in entity_list) {
      final result_1 = await db.rawQuery('''
        SELECT * FROM Songs WHERE song_path = '${preventSqlInjection(entity.getFullPath())}'
      ''');
      if (result_1.length == 1) continue;
      if (result_1.isEmpty) {
        await addSong(entity);
      }
    }
  }

  static void sortSongList(List<Song> song_list, SortingStyle sort) {
    switch (sort.sort_type) {
      case 0: return;
      case 1:
        song_list.sort((a, b) => (sort.is_asc?1:-1)*a.song_name.compareTo(b.song_name));
        return;
      case 2:
        song_list.sort((a, b) => (sort.is_asc?1:-1)*a.song_path.compareTo(b.song_path));
        return;
    }
  }

  Future<Song> addSong(FileEntity entity) async {
    final String song_name = preventSqlInjection(entity.getFileName());
    await db.rawInsert('''
      INSERT INTO Songs (song_name, song_path, is_video)
      VALUES ('$song_name', '${preventSqlInjection(entity.getFullPath())}', ${entity.file_type == FileType.video});
    ''');
    final result = await db.rawQuery('''
      SELECT * FROM Songs where song_path = '${preventSqlInjection(entity.getFullPath())}'
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
  Future<bool> changeSongVolume(int song_id, double volume) async {
    await db.rawUpdate('''
      UPDATE Songs
      SET volume = $volume
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
      print(err);
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
  Future<bool> renameTag(String new_tag_name, int tag_id) async {
    try {
      await db.rawUpdate('''
        UPDATE Tags
        SET tag_name = '$new_tag_name'
        WHERE tag_id = $tag_id
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
    List<List<List<int>>> condition_converted = condition_list.map((inner_list) => inner_list.map((condition) => [condition.condition, condition.value]).toList()).toList();
    try {
      int row_id = await db.rawInsert('''
        INSERT INTO Playlists (playlist_name, is_filtered_playlist, condition_list_json, outer_operator_list_json, inner_operator_list_json)
        VALUES ('$playlist_name', 1, '${jsonEncode(condition_converted)}', '${jsonEncode(outer_condition_list)}', '${jsonEncode(inner_condition_list)}')
      ''');
      await refreshFilteredPlaylist(row_id);

      return true;
    } catch (err) {
      print(err);
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
  Future<bool> renamePlaylist(int playlist_id, String new_name) async {
    try {
      await db.rawUpdate('''
        UPDATE Playlists
        SET playlist_name = '$new_name'
        WHERE playlist_id = $playlist_id
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

  Future<List<Song>> getAllSongs(SortingStyle sort) async {
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Songs
      ''');
      final List<Song> song_list = result.map((song_map) => Song.fromMap(song_map)).toList();
      sortSongList(song_list, sort);
      return song_list;
    } catch (err) {
      return [];
    }
  }
  Future<List<Song>> getAllSongsFromPlaylist(Playlist playlist, SortingStyle sort) async {
    List<Song> return_arr = [];
    for (final int song_id in playlist.song_id_list) {
      final result = await db.rawQuery('''
        Select * FROM Songs WHERE song_id = $song_id
      ''');
      return_arr.add(Song.fromMap(result.first));
    }
    sortSongList(return_arr, sort);
    return return_arr;
  }
  Future<Song> getSongFromEntity(FileEntity entity) async {
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Songs where song_path = '${preventSqlInjection(entity.getFullPath())}'
      ''');
      if (result.isNotEmpty) return Song.fromMap(result.first);
      return Song("Error", "Error", [], "Error", 1, false, -1);
    } catch (err) {
      print(err);
      return Song("Error", "Error", [], "Error", 1, false, -1);
    }
  }
  Future<Song> getSongFromId(int song_id) async {
    final result = await db.rawQuery('''
      SELECT * FROM Songs WHERE song_id = $song_id
    ''');
    return Song.fromMap(result.first);
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
  Future<Tag> getTagFromTagId(int tag_id) async {
    final result = await db.rawQuery('''
      SELECT * FROM Tags WHERE tag_id = $tag_id
    ''');
    return Tag.fromMap(result.first);
  }

  Future<List<Playlist>> getAllPlaylists({ SortingStyle sort = SortingStyle.none }) async {
    try {
      final result = await db.rawQuery('''
        SELECT * FROM Playlists
      ''');
      final List<Playlist> playlist_list = result.map((playlist_map) => Playlist.fromMap(playlist_map)).toList();
      switch (sort) {
        case SortingStyle.none: 
        case SortingStyle.fileNameAsc:
        case SortingStyle.fileNameDesc:
          return playlist_list;
        case SortingStyle.nameAsc: return playlist_list..sort((a, b) => a.playlist_name.compareTo(b.playlist_name));
        case SortingStyle.nameDesc: return playlist_list..sort((a, b) => b.playlist_name.compareTo(a.playlist_name));
      }
    } catch (err) {
      return [];
    }
  }
  Future<Playlist> getPlaylistFromId(int playlist_id) async {
    final result = await db.rawQuery('''
      SELECT * FROM Playlists WHERE playlist_id = $playlist_id
    ''');
    return Playlist.fromMap(result.first);
  }

  Future<void> importDatabase(File new_file) async {
    await new_file.copy(database_path);
  }
  Future<void> exportDatabase() async {
    final File database_file = File(database_path);
    
    await database_file.copy("/storage/emulated/0/Download/Song_Player.db");
  }
}