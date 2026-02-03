import '../database/menu_repository.dart';
import '../models/order.dart';

class MenuService {
  static final List<MenuItem> _defaultItems = [
    MenuItem(id: '1', name: 'Pechuga asada', price: 15000),
    MenuItem(id: '2', name: 'Cerdo Asado', price: 15000),
    MenuItem(id: '3', name: 'Chuleta de cerdo', price: 15000),
    MenuItem(id: '4', name: 'Cerdo al vino', price: 15000),
    MenuItem(id: '5', name: 'Pechuga gratinada', price: 16000),
  ];

  // Iniciar la base de datos con los datos por defecto si está vacía
  static Future<void> _initializeDefaults() async {
    final menuItems = await MenuRepository().getAllMenuItems();
    if (menuItems.isEmpty) {
      for (final item in _defaultItems) {
        await MenuRepository().insertMenuItem(item);
      }
    }
  }

  // Obtener items del menu de la base de datos
  static Future<List<MenuItem>> getMenuItems() async {
    await _initializeDefaults();
    final items = await MenuRepository().getAllMenuItems();
    
    // Eliminar duplicados basados en ID
    final Map<String, MenuItem> uniqueItems = {};
    for (var item in items) {
      uniqueItems[item.id] = item;
    }
    
    return uniqueItems.values.toList();
  }

  // Obtener un item por ID desde la base de datos
  static Future<MenuItem?> getMenuItemById(String id) async {
    final menuItems = await MenuRepository().getAllMenuItems();
    try {
      return menuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Agregar nuevo item al menú
  static Future<void> addMenuItem(String name, double price) async {
    final newItem = MenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
    );
    await MenuRepository().insertMenuItem(newItem);
  }

  // Actualizar un item del menú
  static Future<void> updateMenuItem(
    String id,
    String name,
    double price,
  ) async {
    final updateItem = MenuItem(id: id, name: name, price: price);
    await MenuRepository().updateMenuItem(updateItem);
  }

  static Future<void> deleteMenuItem(String id) async {
    await MenuRepository().deleteMenuItem(id);
  }

  // Método para limpiar duplicados en la base de datos (ejecutar una vez)
  static Future<void> cleanDatabaseDuplicates() async {
    final db = await MenuRepository().getAllMenuItems();
    
    // Encontrar IDs únicos
    final uniqueIds = <String>{};
    final duplicates = <String>[];
    
    for (var item in db) {
      if (uniqueIds.contains(item.id)) {
        duplicates.add(item.id);
      } else {
        uniqueIds.add(item.id);
      }
    }
    
    // Si hay duplicados, limpiar la tabla y reinsertar
    if (duplicates.isNotEmpty) {
      final Map<String, MenuItem> uniqueItems = {};
      for (var item in db) {
        uniqueItems[item.id] = item;
      }
      
      // Borrar todos
      for (var item in db) {
        await MenuRepository().deleteMenuItem(item.id);
      }
      
      // Reinsertar únicos
      for (var item in uniqueItems.values) {
        await MenuRepository().insertMenuItem(item);
      }
    }
  }
}
