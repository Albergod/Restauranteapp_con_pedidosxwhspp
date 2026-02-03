import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import 'menu_repository.dart';

class OrderRepository {
  static final OrderRepository _instance = OrderRepository._internal();
  factory OrderRepository() => _instance;
  OrderRepository._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Order>> getAllOrders() async {
    final response = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    final orders = <Order>[];
    
    for (final orderMap in response as List) {
      final itemsResponse = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderMap['id']);

      final items = <OrderItem>[];
      for (final itemMap in itemsResponse as List) {
        final menuItem = await MenuRepository().getMenuItemById(itemMap['menu_item_id']);
        if (menuItem != null) {
          items.add(OrderItem(
            menuItem: menuItem,
            quantity: itemMap['quantity'],
          ));
        }
      }

      if (items.isNotEmpty) {
        orders.add(Order(
          id: orderMap['id'],
          customerName: orderMap['customer_name'],
          items: items,
          isDelivery: orderMap['is_delivery'] == 1,
          deliveryAddress: orderMap['delivery_address'],
          isTable: orderMap['is_table'] == 1,
          totalPaid: (orderMap['total_paid'] as num).toDouble(),
          createdAt: DateTime.parse(orderMap['created_at']),
          notes: orderMap['notes'],
        ));
      }
    }

    return orders;
  }

  Future<void> insertOrder(Order order) async {
    await _client.from('orders').insert({
      'id': order.id,
      'customer_name': order.customerName,
      'is_delivery': order.isDelivery ? 1 : 0,
      'delivery_address': order.deliveryAddress,
      'is_table': order.isTable ? 1 : 0,
      'total_paid': order.totalPaid,
      'created_at': order.createdAt.toIso8601String(),
      'notes': order.notes,
    });

    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      await _client.from('order_items').insert({
        'id': '${order.id}_item_$i',
        'order_id': order.id,
        'menu_item_id': item.menuItem.id,
        'quantity': item.quantity,
      });
    }
  }

  Future<void> updateOrder(Order order) async {
    await _client.from('orders').update({
      'customer_name': order.customerName,
      'is_delivery': order.isDelivery ? 1 : 0,
      'delivery_address': order.deliveryAddress,
      'is_table': order.isTable ? 1 : 0,
      'total_paid': order.totalPaid,
      'notes': order.notes,
    }).eq('id', order.id);

    await _client.from('order_items').delete().eq('order_id', order.id);

    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      await _client.from('order_items').insert({
        'id': '${order.id}_item_$i',
        'order_id': order.id,
        'menu_item_id': item.menuItem.id,
        'quantity': item.quantity,
      });
    }
  }

  Future<void> deleteOrder(String id) async {
    await _client.from('order_items').delete().eq('order_id', id);
    await _client.from('orders').delete().eq('id', id);
  }

  Future<double> getTotalRevenue() async {
    final response = await _client.from('orders').select('total_paid');
    double total = 0;
    for (final row in response as List) {
      total += (row['total_paid'] as num).toDouble();
    }
    return total;
  }

  Future<void> updateOrderPayment(String orderId, double newAmount) async {
    await _client.from('orders').update({
      'total_paid': newAmount,
    }).eq('id', orderId);
  }
}
