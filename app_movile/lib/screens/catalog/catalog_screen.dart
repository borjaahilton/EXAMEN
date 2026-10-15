import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/web_product_card.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos';

  final List<String> _categories = [
    'Todos',
    'Platos Típicos',
    'Sopas & Caldos',
    'Entradas',
    'Bebidas Andinas',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().fetchCatalog();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    final provider = context.read<CatalogProvider>();
    switch (category) {
      case 'Platos Típicos':
        provider.setSearchQuery('Cuy');
        break;
      case 'Sopas & Caldos':
        provider.setSearchQuery('Llunca');
        break;
      case 'Entradas':
        provider.setSearchQuery('Chocho');
        break;
      case 'Bebidas Andinas':
        provider.setSearchQuery('Chicha');
        break;
      default:
        provider.setSearchQuery('');
        _searchController.clear();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('🏔️ ', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sabores de Huaraz',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CatalogProvider>().fetchCatalog(),
        color: AppColors.primary,
        child: isDesktop
            ? _buildDesktopLayout(context, catalog, cart)
            : _buildMobileLayout(context, catalog, cart),
      ),
    );
  }

  // ==========================================
  // VISTA MÓVIL (100% INTACTA PARA CELULAR)
  // ==========================================
  Widget _buildMobileLayout(
    BuildContext context,
    CatalogProvider catalog,
    CartProvider cart,
  ) {
    return Column(
      children: [
        // Barra de Búsqueda
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => context.read<CatalogProvider>().setSearchQuery(v),
            decoration: InputDecoration(
              hintText: 'Buscar platos, trucha, cuy, sopas...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context.read<CatalogProvider>().setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Contenido dinámico según Estado
        Expanded(
          child: _buildStateContent(
            catalog: catalog,
            isDesktop: false,
            itemBuilder: (context, index) {
              final product = catalog.products[index];
              return ProductCard(
                product: product,
                onTap: () => _openDetail(product),
                onAddToCart: () => _addToCart(product, cart),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VISTA WEB / ESCRITORIO (ESTILO DASHBOARD DELIGO)
  // ==========================================
  Widget _buildDesktopLayout(
    BuildContext context,
    CatalogProvider catalog,
    CartProvider cart,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Barra superior: Título y Buscador moderno
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Carta Gastronómica',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explora lo mejor de la cocina andina de Huaraz y Callejón de Huaylas',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => context.read<CatalogProvider>().setSearchQuery(v),
                      decoration: InputDecoration(
                        hintText: 'Buscar en la carta...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<CatalogProvider>().setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Banner Promocional estilo Figma DeliGO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF9A3412)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🏔️ Especialidad del Día',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sabores Auténticos de Huaraz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ingredientes andinos de origen local seleccionados a diario por nuestros cocineros.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=300&q=80',
                        width: 140,
                        height: 95,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Fila de Categorías / Filtros
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Explorar Menú',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    ' platos disponibles',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => _onCategorySelected(cat),
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textMain,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Grid de Platos para Web
              _buildStateContent(
                catalog: catalog,
                isDesktop: true,
                itemBuilder: (context, index) {
                  final product = catalog.products[index];
                  return WebProductCard(
                    product: product,
                    onTap: () => _openDetail(product),
                    onAddToCart: () => _addToCart(product, cart),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // GESTIÓN DE ESTADOS (Carga, Error, Lista Vacía, Contenido)
  // ==========================================
  Widget _buildStateContent({
    required CatalogProvider catalog,
    required bool isDesktop,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    if (catalog.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Consultando la carta andina...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (catalog.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 54, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'No pudimos conectar con el restaurante',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                catalog.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => context.read<CatalogProvider>().fetchCatalog(),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (catalog.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 54, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'No se encontraron platos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Prueba con otro término de búsqueda.'
                    : 'Actualmente no hay platos disponibles en esta categoría.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: catalog.products.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 310,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: itemBuilder,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: catalog.products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: itemBuilder,
    );
  }

  void _openDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _addToCart(ProductModel product, CartProvider cart) {
    cart.addItem(product, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡1x ${product.nombre} agregado al pedido!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),
    );
  }
}
