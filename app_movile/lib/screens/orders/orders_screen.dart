import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<OrderProvider>().fetchMyOrders(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Pedidos', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadOrders,
            tooltip: 'Actualizar pedidos',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadOrders(),
        color: AppColors.primary,
        child: Builder(
          builder: (context) {
            if (orderProvider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Consultando tus pedidos...', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              );
            }

            if (orderProvider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(orderProvider.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: _loadOrders,
                        child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (orderProvider.myOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Aún no has realizado pedidos',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Los pedidos que envíes aparecerán aquí con seguimiento en vivo.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orderProvider.myOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final order = orderProvider.myOrders[index];
                return _buildOrderCard(order);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID, Modalidad y Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.tipoEntrega == 'recojo' ? '📦 Para Recojo' : '🍽️ En Salón / Mesa',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              OrderStatusBadge(status: order.estado),
            ],
          ),
          const SizedBox(height: 14),

          // Línea de Progreso Visual de Estado
          _buildStatusProgress(order.estado),
          const SizedBox(height: 14),

          const Divider(color: AppColors.border),
          const SizedBox(height: 8),

          // Lista de Platos pedidos
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.cantidad}x ${item.nombreProducto}',
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textMain),
                  ),
                  Text(
                    'S/. ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),

          if (order.notas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nota: ${order.notas}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fecha: ${order.fecha.split("T").first}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Row(
                children: [
                  const Text('Total: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    'S/. ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress(String estado) {
    int currentStep = 0;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        currentStep = 1;
        break;
      case 'en preparacion':
        currentStep = 2;
        break;
      case 'listo':
        currentStep = 3;
        break;
      case 'entregado':
        currentStep = 4;
        break;
    }

    return Row(
      children: [
        _buildStepDot(1, 'Pendiente', currentStep >= 1, currentStep == 1),
        _buildStepLine(currentStep >= 2),
        _buildStepDot(2, 'Preparando', currentStep >= 2, currentStep == 2),
        _buildStepLine(currentStep >= 3),
        _buildStepDot(3, 'Listo', currentStep >= 3, currentStep == 3),
        _buildStepLine(currentStep >= 4),
        _buildStepDot(4, 'Entregado', currentStep >= 4, currentStep == 4),
      ],
    );
  }

  Widget _buildStepDot(int step, String label, bool isCompleted, bool isCurrent) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: AppColors.primaryLight, width: 3) : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            color: isCompleted ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        color: isActive ? AppColors.primary : AppColors.border,
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }
}
