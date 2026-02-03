import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class MenuRepository {
  static final MenuRepository _instance = MenuRepository._internal();
  factory MenuRepository() => _instance;
  MenuRepository._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<MenuItem>> getAllMenuItems() async {
    final response = await _client
        .from('menu_items')
        .select()
        .order('name');
    
    return (response as List).map((map) => MenuItem(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
    )).toList();
  }

  Future<MenuItem?> getMenuItemById(String id) async {
    final response = await _client
        .from('menu_items')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    
    return MenuItem(
      id: response['id'],
      name: response['name'],
      price: (response['price'] as num).toDouble(),
    );
  }

  Future<void> insertMenuItem(MenuItem item) async {
    await _client.from('menu_items').upsert({
      'id': item.id,
      'name': item.name,
      'price': item.price,
    });
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await _client.from('menu_items').update({
      'name': item.name,
      'price': item.price,
    }).eq('id', item.id);
  }

  Future<void> deleteMenuItem(String id) async {
    await _client.from('menu_items').delete().eq('id', id);
  }
}
