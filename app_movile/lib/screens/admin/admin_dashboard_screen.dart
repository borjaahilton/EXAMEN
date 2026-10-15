import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/order_status_badge.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<AdminProvider>().fetchAdminData(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();

    final pages = [
      _buildOrdersTab(admin, auth),
      _buildProductsTab(admin, auth),
      _buildProfileTab(auth),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Text('⚙️ ', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel de Administración',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  auth.currentUser?.email ?? 'admin@sabores.com',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Actualizar datos',
            onPressed: _loadData,
          ),
        ],
      ),
      body: admin.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Sincronizando con Django API...', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          : IndexedStack(
              index: _currentTab,
              children: pages,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: admin.pendingOrdersCount > 0,
              label: Text('${admin.pendingOrdersCount}'),
              backgroundColor: AppColors.warning,
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'Comandas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Carta y Precios',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Plato'),
              onPressed: () => _showCreateProductDialog(context, auth.token!),
            )
          : null,
    );
  }

  // ==========================================================
  // PESTAÑA 1: COMANDAS Y PEDIDOS (ADMIN)
  // ==========================================================
  Widget _buildOrdersTab(AdminProvider admin, AuthProvider auth) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjetas de Resumen KPI
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Pendientes',
                  '${admin.pendingOrdersCount}',
                  const Color(0xFFFEF3C7),
                  const Color(0xFFB45309),
                  Icons.access_time_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  'En Cocina',
                  '${admin.cookingOrdersCount}',
                  const Color(0xFFDBEAFE),
                  const Color(0xFF1D4ED8),
                  Icons.soup_kitchen_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  'Ventas S/.',
                  admin.totalRevenue.toStringAsFixed(0),
                  const Color(0xFFDCFCE7),
                  const Color(0xFF15803D),
                  Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Comandas Registradas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain),
          ),
          const SizedBox(height: 8),

          if (admin.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No hay pedidos registrados en el sistema.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...admin.orders.map((order) => _buildAdminOrderCard(order, admin, auth.token!)),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOrderCard(OrderModel order, AdminProvider admin, String token) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comanda #${order.id}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              OrderStatusBadge(status: order.estado),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cliente: ${order.notas.isNotEmpty ? order.notas : 'cliente@sabores.com'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),

          // Items
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.cantidad}x ${item.nombreProducto}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'S/. ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 18),

          // Total y Selector de Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: S/. ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              DropdownButton<String>(
                value: order.estado,
                isDense: true,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(10),
                items: const [
                  DropdownMenuItem(value: 'pendiente', child: Text('🟡 Pendiente')),
                  DropdownMenuItem(value: 'en preparacion', child: Text('🔵 En preparación')),
                  DropdownMenuItem(value: 'listo', child: Text('🟣 Listo')),
                  DropdownMenuItem(value: 'entregado', child: Text('🟢 Entregado')),
                ],
                onChanged: (newVal) async {
                  if (newVal != null && newVal != order.estado) {
                    final ok = await admin.updateOrderStatus(order.id, newVal, token);
                    if (mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Comanda #${order.id} cambiada a "$newVal"'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PESTAÑA 2: GESTIÓN DE LA CARTA (ADMIN)
  // ==========================================================
  Widget _buildProductsTab(AdminProvider admin, AuthProvider auth) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: admin.products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = admin.products[index];
          return _buildAdminProductCard(product, admin, auth.token!);
        },
      ),
    );
  }

  Widget _buildAdminProductCard(ProductModel p, AdminProvider admin, String token) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              p.imagenUrl.isNotEmpty
                  ? p.imagenUrl
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
                  p.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'S/. ${p.precio.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Switch de disponibilidad
                    GestureDetector(
                      onTap: () => admin.toggleProductAvailability(p, token),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.disponible ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.disponible ? '🟢 Disponible' : '🔴 Agotado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.disponible ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Botón para editar precio
                    GestureDetector(
                      onTap: () => _showEditPriceDialog(context, p, admin, token),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 13, color: AppColors.textMain),
                            SizedBox(width: 4),
                            Text('Precio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, ProductModel p, AdminProvider admin, String token) {
    final controller = TextEditingController(text: p.precio.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modificar Precio: ${p.nombre}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nuevo Precio (S/.)',
            prefixText: 'S/. ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final ok = await admin.updateProductPrice(p.id, newPrice, token);
                if (ok) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Precio de "${p.nombre}" actualizado a S/. ${newPrice.toStringAsFixed(2)}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateProductDialog(BuildContext context, String token) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final imgCtrl = TextEditingController();
    bool disponible = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Plato para la Carta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Plato *'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio (S/.) *', prefixText: 'S/. '),
                ),
                TextField(
                  controller: imgCtrl,
                  decoration: const InputDecoration(labelText: 'URL de Imagen (Opcional)'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Disponible de inmediato'),
                  value: disponible,
                  onChanged: (val) => setModalState(() => disponible = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final nombre = nameCtrl.text.trim();
                final precio = double.tryParse(priceCtrl.text) ?? 0.0;
                if (nombre.isNotEmpty && precio > 0) {
                  final nav = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final adminProvider = context.read<AdminProvider>();
                  final ok = await adminProvider.createProduct(
                    nombre: nombre,
                    descripcion: descCtrl.text.trim(),
                    precio: precio,
                    disponible: disponible,
                    imagenUrl: imgCtrl.text.trim(),
                    token: token,
                  );
                  if (ok) {
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('¡Plato "$nombre" registrado exitosamente en Django!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Crear Plato', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PESTAÑA 3: PERFIL / LOGOUT (ADMIN)
  // ==========================================================
  Widget _buildProfileTab(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primary,
            child: Text('A', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          Text(
            auth.currentUser?.nombre ?? 'Administrador',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            auth.currentUser?.email ?? 'admin@sabores.com',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ROL: ADMINISTRADOR (ACCESO TOTAL)',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Cerrar Sesión Admin', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              onPressed: () async {
                await auth.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
