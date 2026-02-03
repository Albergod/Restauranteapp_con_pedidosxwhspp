class MenuItem {
  final String id;
  final String name;
  final double price;

  MenuItem({required this.id, required this.name, required this.price});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ← NUEVA CLASE: Item individual en un pedido
class OrderItem {
  final MenuItem menuItem;
  final int quantity;

  OrderItem({
    required this.menuItem,
    required this.quantity,
  });

  double get subtotal => menuItem.price * quantity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.menuItem == menuItem &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => menuItem.hashCode ^ quantity.hashCode;
}

class Order {
  final String id;
  final String customerName;
  final List<OrderItem> items; // ← CAMBIO: ahora es una lista
  final bool isDelivery;
  final String? deliveryAddress;
  final bool isTable;
  final double totalPaid;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.isDelivery,
    this.deliveryAddress,
    required this.isTable,
    required this.totalPaid,
    required this.createdAt,
  });

  // Calcula el precio total sumando todos los items
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.subtotal);
  
  double get remainingBalance => totalPrice - totalPaid;

  // Helper para compatibilidad con código que usa un solo item
  MenuItem? get menuItem => items.isNotEmpty ? items.first.menuItem : null;
  int get quantity => items.isNotEmpty ? items.first.quantity : 0;
}
