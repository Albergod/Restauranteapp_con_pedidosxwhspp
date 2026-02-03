-- Ejecuta este SQL en Supabase Dashboard > SQL Editor

-- Tabla de items del menú
CREATE TABLE menu_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price REAL NOT NULL
);

-- Tabla de pedidos
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  is_delivery INTEGER NOT NULL DEFAULT 1,
  delivery_address TEXT,
  is_table INTEGER NOT NULL DEFAULT 0,
  total_paid REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  notes TEXT
);

-- Tabla de items de pedido
CREATE TABLE order_items (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id TEXT NOT NULL REFERENCES menu_items(id),
  quantity INTEGER NOT NULL
);

-- Habilitar RLS (Row Level Security) pero permitir todo por ahora
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Políticas para permitir acceso público (ajustar según necesidad)
CREATE POLICY "Allow all on menu_items" ON menu_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on orders" ON orders FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on order_items" ON order_items FOR ALL USING (true) WITH CHECK (true);

-- Insertar items de menú por defecto
INSERT INTO menu_items (id, name, price) VALUES
  ('1', 'Pechuga asada', 15000),
  ('2', 'Cerdo Asado', 15000),
  ('3', 'Chuleta de cerdo', 15000),
  ('4', 'Cerdo al vino', 15000),
  ('5', 'Pechuga gratinada', 16000);
