import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'payment_parser.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'soundbox_transactions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT,
        amount REAL,
        upiRef TEXT,
        source TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<int> insertTransaction(Transaction transaction) async {
    Database db = await database;
    return await db.insert('transactions', {
      'sender': transaction.sender,
      'amount': transaction.amount,
      'upiRef': transaction.upiRef,
      'source': transaction.source,
      'timestamp': transaction.timestamp.toIso8601String(),
    });
  }

  Future<List<Transaction>> getAllTransactions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction(
        sender: maps[i]['sender'],
        amount: maps[i]['amount'],
        upiRef: maps[i]['upiRef'],
        source: maps[i]['source'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
      );
    });
  }
}
