import 'package:flutter/material.dart';
import '../models/order.dart';
import '../service/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = _order.totalPaid >= _order.totalPrice;
    final hasChange = _order.totalPaid > _order.totalPrice;
    final change = _order.totalPaid - _order.totalPrice;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasChanges);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalles del Pedido'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.pending,
                        color: isPaid ? Colors.green : Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPaid ? 'PAGADO' : 'PENDIENTE',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? Colors.green : Colors.orange,
                              ),
                            ),
                            if (!isPaid)
                              Text(
                                'Falta: \$${_order.remainingBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (hasChange)
                              Text(
                                'Vueltos: \$${change.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Cliente'),
              _buildInfoCard(
                icon: Icons.person,
                title: 'Nombre',
                value: _order.customerName,
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Pedido'),
              ..._order.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _order.items.length - 1 ? 8 : 0,
                  ),
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cantidad: ${item.quantity} x \$${item.menuItem.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              if (_order.notes != null && _order.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Notas del Pedido'),
                Card(
                  elevation: 1,
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_alt, color: Colors.orange, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _order.notes!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              _buildSectionTitle('Tipo de Servicio'),
              _buildInfoCard(
                icon: _order.isDelivery
                    ? Icons.delivery_dining
                    : Icons.table_restaurant,
                title: _order.isDelivery ? 'Domicilio' : 'Mesa',
                value: _order.isDelivery && _order.deliveryAddress != null
                    ? _order.deliveryAddress!
                    : 'Servicio en mesa',
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Información de Pago'),
              _buildInfoCard(
                icon: Icons.calculate,
                title: 'Total',
                value: '\$${_order.totalPrice.toStringAsFixed(2)}',
                valueColor: Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                icon: Icons.payment,
                title: 'Pagado',
                value: '\$${_order.totalPaid.toStringAsFixed(2)}',
                valueColor: Colors.blue.shade700,
              ),

              if (!isPaid) ...[
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: Icons.pending_actions,
                  title: 'Pendiente',
                  value: '\$${_order.remainingBalance.toStringAsFixed(2)}',
                  valueColor: Colors.red.shade700,
                ),
              ] else if (hasChange) ...[
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Vueltos',
                  value: '\$${change.toStringAsFixed(2)}',
                  valueColor: Colors.blue.shade700,
                ),
              ],

              const SizedBox(height: 24),

              _buildSectionTitle('Fecha y Hora'),
              _buildInfoCard(
                icon: Icons.access_time,
                title: 'Creado',
                value:
                    '${_order.createdAt.day}/${_order.createdAt.month}/${_order.createdAt.year} - ${_order.createdAt.hour.toString().padLeft(2, '0')}:${_order.createdAt.minute.toString().padLeft(2, '0')}',
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showPaymentDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaid ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    isPaid ? 'Modificar Pago' : 'Registrar Pago',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    final paymentController = TextEditingController(
      text: _order.totalPaid > 0 ? _order.totalPaid.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total del pedido: \$${_order.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_order.totalPaid > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Pago actual: \$${_order.totalPaid.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Cantidad que pagó el cliente (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                helperText: 'Puede ser mayor al total (se calcularán vueltos)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(paymentController.text.trim());

              if (amount == null || amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa una cantidad válida'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _updatePayment(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePayment(double newAmount) async {
    setState(() => _isLoading = true);

    try {
      await OrderService.updateOrderPayment(_order.id, newAmount);

      final hasChange = newAmount > _order.totalPrice;
      final change = newAmount - _order.totalPrice;

      setState(() {
        _order = Order(
          id: _order.id,
          customerName: _order.customerName,
          items: _order.items,
          isDelivery: _order.isDelivery,
          deliveryAddress: _order.deliveryAddress,
          isTable: _order.isTable,
          totalPaid: newAmount,
          createdAt: _order.createdAt,
          notes: _order.notes,
        );
        _isLoading = false;
        _hasChanges = true;
      });

      if (mounted) {
        String message = 'Pago actualizado exitosamente';
        if (hasChange) {
          message += '\nVueltos: \$${change.toStringAsFixed(2)}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pedido'),
        content: Text(
          '¿Estás seguro que deseas eliminar el pedido de ${_order.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder() async {
    setState(() => _isLoading = true);

    try {
      await OrderService.deleteOrder(_order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
