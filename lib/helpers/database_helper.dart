// This file is no longer used since all data is stored in Firestore.
// You could safely delete or fully comment out the following if local DB is not needed.
// ...existing code removed or commented out...
import 'package:formbot/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE uploaded_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE asr_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        response TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE llm_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        response TEXT
      )
    ''');
  }

  Future<int> insertUserInfo(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('user_info', row);
  }

  Future<int> insertUploadedImage(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('uploaded_images', row);
  }

  Future<int> insertAsrResponse(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('asr_responses', row);
  }

  Future<int> insertLlmResponse(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('llm_responses', row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  Future<void> saveUserInfo(String name) async {
    UserInfo userInfo = UserInfo(name: name);
    await insertUserInfo(userInfo.toMap());
  }

  Future<void> saveUploadedImage(String url) async {
    UploadedImage uploadedImage = UploadedImage(url: url);
    await insertUploadedImage(uploadedImage.toMap());
  }

  Future<void> saveAsrResponse(String response) async {
    AsrResponse asrResponse = AsrResponse(response: response);
    await insertAsrResponse(asrResponse.toMap());
  }

  Future<void> saveLlmResponse(String response) async {
    LlmResponse llmResponse = LlmResponse(response: response);
    await insertLlmResponse(llmResponse.toMap());
  }
}
