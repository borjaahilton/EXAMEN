import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onOrderPlaced;

  const CartScreen({super.key, this.onOrderPlaced});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _tipoEntrega = 'recojo';
  final _notasController = TextEditingController();

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (cart.isEmpty) return;

    if (!auth.isAuthenticated || auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe iniciar sesión para enviar un pedido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await orderProvider.submitOrder(
      tipoEntrega: _tipoEntrega,
      notas: _notasController.text.trim(),
      cartItems: cart.items,
      token: auth.token!,
    );

    if (!mounted) return;

    if (success) {
      final orderId = orderProvider.lastCreatedOrder?.id;
      cart.clear();
      _notasController.clear();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('¡Pedido Confirmado!'),
            ],
          ),
          content: Text(
            'Tu comanda #$orderId ha sido enviada a la cocina de Sabores de Huaraz.\n\nPuedes revisar el estado en la pestaña "Mis Pedidos".',
            style: const TextStyle(fontSize: 14.5, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.onOrderPlaced != null) {
                  widget.onOrderPlaced!();
                }
              },
              child: const Text('Ver Mis Pedidos', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Error al procesar el pedido'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mi Carrito de Pedido', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 68, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Tu carrito está vacío',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explora la carta y agrega tus platos huaracinos favoritos.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmar Pedido', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
            tooltip: 'Vaciar carrito',
            onPressed: () => cart.clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Lista de Items
                ...cart.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.product.imagenUrl.isNotEmpty
                                ? item.product.imagenUrl
                                : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=100&q=80',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 60,
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.restaurant, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.nombre,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S/. ${item.product.precio.toStringAsFixed(2)} c/u',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        // Controles de cantidad
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 22, color: AppColors.primary),
                              onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 22, color: AppColors.primary),
                              onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Modalidad de Entrega
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modalidad de Entrega',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('📦 Para Recojo'),
                              selected: _tipoEntrega == 'recojo',
                              selectedColor: AppColors.primaryLight,
                              labelStyle: TextStyle(
                                color: _tipoEntrega == 'recojo' ? AppColors.primary : AppColors.textMain,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _tipoEntrega = 'recojo');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('🍽️ En Salón / Mesa'),
                              selected: _tipoEntrega == 'consumo_local',
                              selectedColor: AppColors.primaryLight,
                              labelStyle: TextStyle(
                                color: _tipoEntrega == 'consumo_local' ? AppColors.primary : AppColors.textMain,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _tipoEntrega = 'consumo_local');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Notas para cocina
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instrucciones Especiales',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notasController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ej. Ají por separado, término medio, etc.',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barra inferior con Total y Enviar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a Pagar:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                      Text(
                        'S/. ${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: 'Confirmar y Enviar Pedido',
                    isLoading: orderProvider.isSubmitting,
                    icon: Icons.check_circle_outline,
                    onPressed: _handleConfirmOrder,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
