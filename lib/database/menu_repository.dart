import '../models/order.dart';
import '../models/models.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class MenuRepository {
  static final MenuRepository _instance = MenuRepository._internal();
  factory MenuRepository() => _instance;
  MenuRepository._internal();

  Future<List<MenuItem>> getAllMenuItems() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('menu_items');
    return maps.map((map) => MenuItemDB.fromMap(map).toMenuItem()).toList();
  }

  Future<void> insertMenuItem(MenuItem item) async {
    final db = await DatabaseHelper().database;
    final itemDB = MenuItemDB(id: item.id, name: item.name, price: item.price);
    await db.insert(
      'menu_items',
      itemDB.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMenuItem(MenuItem item) async {
    final db = await DatabaseHelper().database;
    final itemDB = MenuItemDB(id: item.id, name: item.name, price: item.price);
    await db.update(
      'menu_items',
      itemDB.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteMenuItem(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
