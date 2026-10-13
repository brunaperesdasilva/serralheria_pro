import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('serralheria_pro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE clients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      address TEXT,
      email TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clientId INTEGER NOT NULL,
      clientName TEXT NOT NULL,
      serviceDescription TEXT NOT NULL,
      baseValue REAL NOT NULL,
      profitMargin REAL NOT NULL,
      finalValue REAL NOT NULL,
      itemsJson TEXT NOT NULL DEFAULT '[]',
      discount REAL NOT NULL DEFAULT 0,
      additionalValue REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'draft',
      createdAt TEXT,
      validUntil TEXT,
      notes TEXT NOT NULL DEFAULT ''
    )
    ''');

    await _createMaterialsTable(db);

    await _createStockMovementsTable(db);

    await db.execute('''
    CREATE TABLE schedules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clientId INTEGER NOT NULL,
      clientName TEXT NOT NULL,
      serviceDescription TEXT NOT NULL,
      date TEXT NOT NULL,
      time TEXT NOT NULL,
      status TEXT NOT NULL,
      address TEXT NOT NULL DEFAULT '',
      notes TEXT NOT NULL DEFAULT '',
      budgetId INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      companyName TEXT NOT NULL,
      responsibleName TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT NOT NULL,
      cnpj TEXT NOT NULL DEFAULT '',
      logoBase64 TEXT
    )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Senhas locais antigas nao devem permanecer armazenadas no aparelho.
      await db.execute('DROP TABLE IF EXISTS users');
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE budgets ADD COLUMN itemsJson TEXT NOT NULL DEFAULT '[]'");
      await db.execute(
          'ALTER TABLE budgets ADD COLUMN discount REAL NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE budgets ADD COLUMN additionalValue REAL NOT NULL DEFAULT 0');
      await db.execute(
          "ALTER TABLE budgets ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'");
      await db.execute('ALTER TABLE budgets ADD COLUMN createdAt TEXT');
      await db.execute('ALTER TABLE budgets ADD COLUMN validUntil TEXT');
      await db.execute(
          "ALTER TABLE budgets ADD COLUMN notes TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 4) {
      await _createStockMovementsTable(db);
    }
    if (oldVersion < 5) {
      await db.execute(
          "ALTER TABLE schedules ADD COLUMN address TEXT NOT NULL DEFAULT ''");
      await db.execute(
          "ALTER TABLE schedules ADD COLUMN notes TEXT NOT NULL DEFAULT ''");
      await db.execute('ALTER TABLE schedules ADD COLUMN budgetId INTEGER');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE materials RENAME TO materials_legacy');
      await _createMaterialsTable(db);
      await db.execute('''
        INSERT INTO materials (id, name, quantity, minimumQuantity, costPrice)
        SELECT id, name, quantity, minimumQuantity, costPrice
        FROM materials_legacy
      ''');
      await db.execute('DROP TABLE materials_legacy');
    }
    if (oldVersion < 7) {
      await db.execute(
          "ALTER TABLE profile ADD COLUMN cnpj TEXT NOT NULL DEFAULT ''");
      await db.execute('ALTER TABLE profile ADD COLUMN logoBase64 TEXT');
    }
  }

  Future<void> _createMaterialsTable(Database db) => db.execute('''
    CREATE TABLE materials (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      minimumQuantity INTEGER NOT NULL,
      costPrice REAL NOT NULL
    )
  ''');

  Future<void> _createStockMovementsTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS stock_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      materialId INTEGER NOT NULL,
      materialName TEXT NOT NULL,
      type TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      previousQuantity INTEGER NOT NULL,
      newQuantity INTEGER NOT NULL,
      reason TEXT NOT NULL,
      budgetId INTEGER,
      createdAt TEXT NOT NULL
    )
  ''');

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
