const { createClient } = require('@supabase/supabase-js');
const { SUPABASE_URL, SUPABASE_ANON_KEY } = require('./config');

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function getMenuItems() {
  const { data, error } = await supabase
    .from('menu_items')
    .select('*')
    .order('name');
  
  if (error) {
    console.error('Error obteniendo menú:', error);
    return [];
  }
  return data;
}

async function getMenuItemById(id) {
  const { data, error } = await supabase
    .from('menu_items')
    .select('*')
    .eq('id', id)
    .single();
  
  if (error) return null;
  return data;
}

async function createOrder(customerName, items, deliveryAddress, notes = null) {
  const orderId = Date.now().toString();
  const createdAt = new Date().toISOString();

  let totalPrice = 0;
  for (const item of items) {
    totalPrice += item.price * item.quantity;
  }

  const { error: orderError } = await supabase.from('orders').insert({
    id: orderId,
    customer_name: customerName,
    is_delivery: 1,
    delivery_address: deliveryAddress,
    is_table: 0,
    total_paid: 0,
    created_at: createdAt,
    notes: notes
  });

  if (orderError) {
    console.error('Error creando orden:', orderError);
    throw orderError;
  }

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const { error: itemError } = await supabase.from('order_items').insert({
      id: `${orderId}_item_${i}`,
      order_id: orderId,
      menu_item_id: item.menuItemId,
      quantity: item.quantity
    });

    if (itemError) {
      console.error('Error creando item:', itemError);
    }
  }

  return { orderId, totalPrice };
}

module.exports = {
  getMenuItems,
  getMenuItemById,
  createOrder
};
