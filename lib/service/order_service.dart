
import '../models/order.dart';
import '../database/order_repository.dart';

class OrderService {
  // Obtener todos los pedidos desde la base de datos
  static Future<List<Order>> getOrders() async {
    return await OrderRepository().getAllOrders();
  }

  // Guardar pedido con UN SOLO item (para compatibilidad)
  static Future<void> addOrder({
    required String customerName,
    required MenuItem menuItem,
    required int quantity,
    required bool isDelivery,
    String? deliveryAddress,
    required bool isTable,
    required double totalpaid,
    String? notes,
  }) async {
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: customerName,
      items: [
        OrderItem(menuItem: menuItem, quantity: quantity),
      ],
      isDelivery: isDelivery,
      deliveryAddress: deliveryAddress,
      isTable: isTable,
      totalPaid: totalpaid,
      createdAt: DateTime.now(),
      notes: notes,
    );
    await OrderRepository().insertOrder(order);
  }

  // ← NUEVO: Guardar pedido con MÚLTIPLES items
  static Future<void> addMultipleItemsOrder({
    required String customerName,
    required List<OrderItem> items,
    required bool isDelivery,
    String? deliveryAddress,
    required bool isTable,
    required double totalpaid,
    String? notes,
  }) async {
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: customerName,
      items: items,
      isDelivery: isDelivery,
      deliveryAddress: deliveryAddress,
      isTable: isTable,
      totalPaid: totalpaid,
      createdAt: DateTime.now(),
      notes: notes,
    );
    await OrderRepository().insertOrder(order);
  }

  static Future<void> updateOrder(String id, Order updateOrder) async {
    await OrderRepository().updateOrder(updateOrder);
  }

  static Future<void> deleteOrder(String id) async {
    await OrderRepository().deleteOrder(id);
  }

  static Future<double> getTotalRevenue() async {
    return await OrderRepository().getTotalRevenue();
  }

  // Actualizar pago de una orden
  static Future<void> updateOrderPayment(
    String orderId,
    double newAmount,
  ) async {
    await OrderRepository().updateOrderPayment(orderId, newAmount);
  }
}
