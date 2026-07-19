import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AccountDatabase {
  static final AccountDatabase instance = AccountDatabase._init();
  static Database? _database;
  AccountDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounts.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        email TEXT PRIMARY KEY,
        nickname TEXT NOT NULL
      )
    ''');
  }

  Future<void> upsertAccount(String email, String nickname) async {
    final db = await instance.database;
    await db.insert('accounts', {
      'email': email,
      'nickname': nickname,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await instance.database;
    return db.query('accounts', orderBy: 'nickname ASC');
  }

  Future<void> deleteAccount(String email) async {
    final db = await instance.database;
    await db.delete('accounts', where: 'email = ?', whereArgs: [email]);
  }
}
