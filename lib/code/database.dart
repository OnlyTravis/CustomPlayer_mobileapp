import 'package:sqflite/sqflite.dart';

late Database db;
Future<void> initDatabase() async {
  db = await openDatabase('Song_Player.db');
}