import 'package:flutter/material.dart';
import 'package:restaurante_app/models/order.dart';
import 'package:restaurante_app/service/menu_service.dart';
import 'package:restaurante_app/service/order_service.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formkey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _notesController = TextEditingController();

  String _customerName = '';
  MenuItem? _selectedMenuItem;
  int _quantity = 1;
  bool _isDelivery = true;
  bool _isTable = false;
  String _deliveryAddress = '';
  final double _totalPaid = 0.0;
  bool _isLoading = false;

  // Variables para modo múltiple
  bool _isMultipleMode = false;
  final Map<MenuItem, int> _multipleItems = {};

  @override
  void dispose() {
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuItem>>(
      future: MenuService.getMenuItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Nuevo pedido'),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final menuItems = snapshot.data!;
        final totalPrice = _isMultipleMode
            ? _calculateMultipleTotal()
            : (_selectedMenuItem != null
                ? _selectedMenuItem!.price * _quantity
                : 0.0);

        return Scaffold(
          appBar: AppBar(
            title: Text(_isMultipleMode ? 'Pedido Múltiple' : 'Nuevo Pedido'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          body: Form(
            key: _formkey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Nombre del cliente con Controller
                TextFormField(
                  controller: _customerNameController, // ← CAMBIO: Usar controller
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cliente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el nombre del cliente';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _customerName = value.trim(); // ← NUEVO: Guardar en tiempo real
                  },
                ),
                const SizedBox(height: 16),

                // Toggle para modo múltiple
                Card(
                  color: _isMultipleMode ? Colors.orange.shade50 : null,
                  child: SwitchListTile(
                    title: const Text(
                      'Pedido Múltiple',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_isMultipleMode
                        ? 'Selecciona varios productos'
                        : 'Activar para pedir múltiples items'),
                    secondary: Icon(
                      _isMultipleMode ? Icons.shopping_cart : Icons.shopping_bag,
                      color: Colors.orange,
                    ),
                    value: _isMultipleMode,
                    onChanged: (value) {
                      setState(() {
                        _isMultipleMode = value;
                        if (!value) {
                          _multipleItems.clear();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Mostrar modo simple o múltiple
                if (_isMultipleMode)
                  _buildMultipleItemsMode(menuItems)
                else
                  _buildSingleItemMode(menuItems),

                const SizedBox(height: 16),

                // Total price display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery options
                SwitchListTile(
                  title: const Text('Es a domicilio'),
                  subtitle: !_isDelivery
                      ? const Text('Se activará el campo de domicilio')
                      : null,
                  value: _isDelivery,
                  onChanged: (value) {
                    setState(() {
                      _isDelivery = value;
                      _isTable = !value;
                      if (!value) {
                        _deliveryAddress = '';
                      }
                    });
                  },
                ),

                SwitchListTile(
                  title: const Text('Es para la mesa'),
                  subtitle: !_isTable
                      ? const Text('Se desactivará el campo de domicilio')
                      : null,
                  value: _isTable,
                  onChanged: (value) {
                    setState(() {
                      _isTable = value;
                      _isDelivery = !value;
                      if (value) {
                        _deliveryAddress = '';
                      }
                    });
                  },
                ),

                if (_isDelivery) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Direccion de entrega',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    validator: (value) {
                      if (_isDelivery && (value == null || value.trim().isEmpty)) {
                        return 'La direccion es requerida para domicilios';
                      }
                      return null;
                    },
                    onSaved: (value) => _deliveryAddress = value!.trim(),
                  ),
                ],
                const SizedBox(height: 16),

                // Notas del pedido
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas del pedido (opcional)',
                    hintText: 'Ej: Sin sopa, ensalada aparte...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar pedido'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleItemMode(List<MenuItem> menuItems) {
    final totalPrice = _selectedMenuItem != null
        ? _selectedMenuItem!.price * _quantity
        : 0.0;

    return Column(
      children: [
        DropdownButtonFormField<MenuItem>(
          decoration: const InputDecoration(
            labelText: 'Menú',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.restaurant_menu),
          ),
          value: _selectedMenuItem,
          items: menuItems.isNotEmpty
              ? menuItems.map((item) {
                  return DropdownMenuItem<MenuItem>(
                    value: item,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.name),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()
              : [],
          validator: (value) {
            if (value == null) {
              return 'Por favor selecciona un item del menú';
            }
            return null;
          },
          onChanged: (MenuItem? newValue) {
            setState(() {
              _selectedMenuItem = newValue;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _quantity.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_shopping_cart),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cantidad requerida';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 1) {
                    return 'cantidad inválida';
                  }
                  return null;
                },
                onSaved: (value) => _quantity = int.parse(value!),
                onChanged: (value) {
                  final newQuantity = int.tryParse(value) ?? 1;
                  setState(() {
                    _quantity = newQuantity;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultipleItemsMode(List<MenuItem> menuItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona los productos y cantidades:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...menuItems.map((item) {
          final quantity = _multipleItems[item] ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                '\$${item.price.toStringAsFixed(2)} c/u',
                style: const TextStyle(color: Colors.green),
              ),
              trailing: SizedBox(
                width: 140,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 0
                          ? () {
                              setState(() {
                                if (quantity == 1) {
                                  _multipleItems.remove(item);
                                } else {
                                  _multipleItems[item] = quantity - 1;
                                }
                              });
                            }
                          : null,
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          _multipleItems[item] = quantity + 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  double _calculateMultipleTotal() {
    double total = 0.0;
    _multipleItems.forEach((item, quantity) {
      total += item.price * quantity;
    });
    return total;
  }

  void _saveOrder() async {
    // ← CAMBIO: Validar primero el formulario
    if (!_formkey.currentState!.validate()) {
      return;
    }

    // ← NUEVO: Validar nombre del cliente específicamente
    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del cliente es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validación para modo múltiple
    if (_isMultipleMode && _multipleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validación para modo simple
    if (!_isMultipleMode && _selectedMenuItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un producto del menú'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _formkey.currentState!.save();

    // ← NUEVO: Asegurar que _customerName tenga el valor del controller
    _customerName = _customerNameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isMultipleMode) {
        // Guardar pedido múltiple
        final items = _multipleItems.entries
            .map((entry) => OrderItem(
                  menuItem: entry.key,
                  quantity: entry.value,
                ))
            .toList();

        final notes = _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null;

        await OrderService.addMultipleItemsOrder(
          customerName: _customerName,
          items: items,
          isDelivery: _isDelivery,
          deliveryAddress: _isDelivery ? _deliveryAddress : null,
          isTable: _isTable,
          totalpaid: _totalPaid,
          notes: notes,
        );
      } else {
        // Guardar pedido simple
        final notes = _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null;

        await OrderService.addOrder(
          customerName: _customerName,
          menuItem: _selectedMenuItem!,
          quantity: _quantity,
          isDelivery: _isDelivery,
          deliveryAddress: _isDelivery ? _deliveryAddress : null,
          isTable: _isTable,
          totalpaid: _totalPaid,
          notes: notes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
