import '../models/order.dart';
import '../service/menu_service.dart';
import 'database_helper.dart';
import '../models/models.dart';
import 'package:sqflite/sqflite.dart';

class OrderRepository {
  static final OrderRepository _instance = OrderRepository._internal();
  factory OrderRepository() => _instance;
  OrderRepository._internal();

  // Obtener todos los pedidos
  Future<List<Order>> getAllOrders() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> orderMaps = await db.query('orders');

    final orders = <Order>[];
    for (final orderMap in orderMaps) {
      final orderDB = OrderDB.fromMap(orderMap);

      // Obtener los items de este pedido
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderDB.id],
      );

      final items = <OrderItem>[];
      for (final itemMap in itemMaps) {
        final itemDB = OrderItemDB.fromMap(itemMap);
        final menuItem = await MenuService.getMenuItemById(itemDB.menuItemId);

        if (menuItem != null) {
          items.add(OrderItem(menuItem: menuItem, quantity: itemDB.quantity));
        }
      }

      if (items.isNotEmpty) {
        orders.add(
          Order(
            id: orderDB.id,
            customerName: orderDB.customerName,
            items: items,
            isDelivery: orderDB.isDelivery,
            deliveryAddress: orderDB.deliveryAddress,
            isTable: orderDB.isTable,
            totalPaid: orderDB.totalPaid,
            createdAt: orderDB.createdAt,
          ),
        );
      }
    }

    // Ordenar por fecha de creación
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  // Guardar un pedido con múltiples items
  Future<void> insertOrder(Order order) async {
    final db = await DatabaseHelper().database;

    // Iniciar transacción para garantizar consistencia
    await db.transaction((txn) async {
      // Insertar el pedido
      final orderDB = OrderDB(
        id: order.id,
        customerName: order.customerName,
        isDelivery: order.isDelivery,
        deliveryAddress: order.deliveryAddress,
        isTable: order.isTable,
        totalPaid: order.totalPaid,
        createdAt: order.createdAt,
      );

      await txn.insert(
        'orders',
        orderDB.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insertar cada item del pedido
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        final itemDB = OrderItemDB(
          id: '${order.id}_item_$i',
          orderId: order.id,
          menuItemId: item.menuItem.id,
          quantity: item.quantity,
        );

        await txn.insert(
          'order_items',
          itemDB.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Actualizar un pedido
  Future<void> updateOrder(Order order) async {
    final db = await DatabaseHelper().database;

    await db.transaction((txn) async {
      // Actualizar pedido
      final orderDB = OrderDB(
        id: order.id,
        customerName: order.customerName,
        isDelivery: order.isDelivery,
        deliveryAddress: order.deliveryAddress,
        isTable: order.isTable,
        totalPaid: order.totalPaid,
        createdAt: order.createdAt,
      );

      await txn.update(
        'orders',
        orderDB.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );

      // Eliminar items antiguos
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      // Insertar items actualizados
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        final itemDB = OrderItemDB(
          id: '${order.id}_item_$i',
          orderId: order.id,
          menuItemId: item.menuItem.id,
          quantity: item.quantity,
        );

        await txn.insert(
          'order_items',
          itemDB.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Eliminar un pedido (CASCADE eliminará los items automáticamente)
  Future<void> deleteOrder(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // Obtener ingresos totales
  Future<double> getTotalRevenue() async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery(
      'SELECT SUM(total_paid) as total FROM orders',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Actualizar el pago de una orden
  Future<void> updateOrderPayment(String orderId, double newAmount) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'orders',
      {'total_paid': newAmount},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
