//configuracion de la base de datos
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'restaurante.db');

    return await openDatabase(
      path, 
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE menu_items(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          price REAL NOT NULL
        )
      ''');

    await db.execute('''
        CREATE TABLE orders(
          id TEXT PRIMARY KEY,
          customer_name TEXT NOT NULL,
          is_delivery INT NOT NULL,
          delivery_address TEXT,
          is_table INT NOT NULL, 
          total_paid REAL NOT NULL,
          created_at TEXT NOT NULL,
          notes TEXT
        )
      ''');

    // ← NUEVA TABLA: order_items
    await db.execute('''
        CREATE TABLE order_items(
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          menu_item_id TEXT NOT NULL,
          quantity INT NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
          FOREIGN KEY (menu_item_id) REFERENCES menu_items (id)
        )
      ''');
  }

  // Migración de versión 1 a versión 2
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Crear tabla temporal para los pedidos existentes
      await db.execute('''
          CREATE TABLE orders_backup(
            id TEXT PRIMARY KEY,
            customer_name TEXT NOT NULL,
            menu_item_id TEXT NOT NULL,
            quantity INT NOT NULL,
            is_delivery INT NOT NULL,
            delivery_address TEXT,
            is_table INT NOT NULL, 
            total_paid REAL NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

      // Copiar datos existentes
      await db.execute('''
          INSERT INTO orders_backup 
          SELECT * FROM orders
        ''');

      // Eliminar tabla antigua
      await db.execute('DROP TABLE orders');

      // Crear nueva tabla orders (sin menu_item_id y quantity)
      await db.execute('''
          CREATE TABLE orders(
            id TEXT PRIMARY KEY,
            customer_name TEXT NOT NULL,
            is_delivery INT NOT NULL,
            delivery_address TEXT,
            is_table INT NOT NULL, 
            total_paid REAL NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

      // Crear tabla order_items
      await db.execute('''
          CREATE TABLE order_items(
            id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL,
            menu_item_id TEXT NOT NULL,
            quantity INT NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
            FOREIGN KEY (menu_item_id) REFERENCES menu_items (id)
          )
        ''');

      // Migrar datos: crear pedidos y sus items
      final oldOrders = await db.query('orders_backup');
      for (final oldOrder in oldOrders) {
        // Insertar en nueva tabla orders
        await db.insert('orders', {
          'id': oldOrder['id'],
          'customer_name': oldOrder['customer_name'],
          'is_delivery': oldOrder['is_delivery'],
          'delivery_address': oldOrder['delivery_address'],
          'is_table': oldOrder['is_table'],
          'total_paid': oldOrder['total_paid'],
          'created_at': oldOrder['created_at'],
        });

        // Insertar item en order_items
        await db.insert('order_items', {
          'id': '${oldOrder['id']}_item_1',
          'order_id': oldOrder['id'],
          'menu_item_id': oldOrder['menu_item_id'],
          'quantity': oldOrder['quantity'],
        });
      }

      // Eliminar tabla temporal
      await db.execute('DROP TABLE orders_backup');
    }
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE orders ADD COLUMN notes TEXT');
    }
  }
}
