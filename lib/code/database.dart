import 'package:sqflite/sqflite.dart';

late DatabaseHandler db;

Future<void> initDatabase() async {
  db = DatabaseHandler();
}

class DatabaseHandler {
  late Database db;

  DatabaseHandler() {
    initDatabase();
  } 

  Future<void> initDatabase() async {
    db = await openDatabase('Song_Player.db', onCreate: (Database database, int version) async {
      await database.execute('''
        CREATE TABLE Songs (
          song_name TEXT,
          file_name TEXT PRIMARY_KEY,
          author TEXT
        )
      ''');
      await database.execute('''
        CREATE TABLE Tags (
          tag_name TEXT,
          tag_id INTEGER PRIMARY_KEY
        )
      ''');
    });
  }

  Future<void> createTag(tag) async {
    await db.execute('''
      INSERT INTO Tags 
    ''');
  }
}