//MODELOS PARA SQLITE

import 'package:restaurante_app/models/order.dart';

class MenuItemDB {
  final String id;
  final String name;
  final double price;

  MenuItemDB({required this.id, required this.name, required this.price});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'price': price};
  }

  factory MenuItemDB.fromMap(Map<String, dynamic> map) {
    return MenuItemDB(
      id: map['id'],
      name: map['name'],
      price: map['price'].toDouble(),
    );
  }

  MenuItem toMenuItem() {
    return MenuItem(id: id, name: name, price: price);
  }
}

// ← NUEVO: Modelo para items de pedido
class OrderItemDB {
  final String id;
  final String orderId;
  final String menuItemId;
  final int quantity;

  OrderItemDB({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
    };
  }

  factory OrderItemDB.fromMap(Map<String, dynamic> map) {
    return OrderItemDB(
      id: map['id'],
      orderId: map['order_id'],
      menuItemId: map['menu_item_id'],
      quantity: map['quantity'],
    );
  }
}

class OrderDB {
  final String id;
  final String customerName;
  final bool isDelivery;
  final String? deliveryAddress;
  final bool isTable;
  final double totalPaid;
  final DateTime createdAt;

  OrderDB({
    required this.id,
    required this.customerName,
    required this.isDelivery,
    this.deliveryAddress,
    required this.isTable,
    required this.totalPaid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'is_delivery': isDelivery ? 1 : 0,
      'delivery_address': deliveryAddress,
      'is_table': isTable ? 1 : 0,
      'total_paid': totalPaid,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderDB.fromMap(Map<String, dynamic> map) {
    return OrderDB(
      id: map['id'],
      customerName: map['customer_name'],
      isDelivery: map['is_delivery'] == 1,
      deliveryAddress: map['delivery_address'],
      isTable: map['is_table'] == 1,
      totalPaid: map['total_paid'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
