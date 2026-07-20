import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../domain/repositories/directory_repository.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';
import 'order_history_screen.dart';
import 'select_address_screen.dart';
import 'vendor_detail_screen.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _couponController = TextEditingController();
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<MarketplaceBloc>().add(FetchProducts());
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = RepositoryProvider.of<DirectoryRepository>(context);
      final cats = await repo.getProductCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GROOMING STORE'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.package),
            tooltip: 'Order History',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
              if (context.mounted) {
                context.read<MarketplaceBloc>().add(FetchProducts());
              }
            },
          ),
          _buildCartButton(),
        ],
      ),

      body: BlocConsumer<MarketplaceBloc, MarketplaceState>(
        listener: (context, state) {
          if (state is OrderCreatedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order ${state.order.orderNumber} placed successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MarketplaceLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          } else if (state is ProductsLoaded) {
            final products = state.products;
            final filtered = _selectedCategoryId == null
                ? products
                : products.where((p) => p.categoryId == _selectedCategoryId).toList();
            if (products.isEmpty) {
              return const Center(child: Text('No grooming products registered yet.'));
            }
            return Column(
              children: [
                if (_categories.isNotEmpty) _buildCategoryFilter(),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No products in this category.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(filtered[index], state.cart);
                          },
                        ),
                ),
              ],
            );
          } else if (state is MarketplaceFailure) {
            return Center(child: Text(state.error, style: const TextStyle(color: AppColors.error)));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCartButton() {
    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        int cartCount = 0;
        if (state is ProductsLoaded) {
          cartCount = state.cart.values.fold(0, (sum, qty) => sum + qty);
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.shoppingCart),
              onPressed: cartCount > 0 ? () => _showCartDrawer(context) : null,
            ),
            if (cartCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildCategoryChip('All', null),
          ..._categories.map((c) => _buildCategoryChip(c.name, c.id)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? id) {
    final selected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.black : AppColors.textSecondary)),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.cardBg,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        onSelected: (_) => setState(() => _selectedCategoryId = id),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, Map<String, int> cart) {
    final cartQty = cart[product.id] ?? 0;
    // Resolve primary image: prefer first image in list, fallback to imageUrl
    final images = product.images ?? (product.imageUrl != null ? [product.imageUrl!] : <String>[]);
    final primaryImage = product.imageUrl ?? (images.isNotEmpty ? images.first : null);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary image only (tap → detail modal with full gallery)
          Expanded(
            child: GestureDetector(
              onTap: () => _openProductDetail(product),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_img_${product.id}',
                      child: primaryImage != null
                          ? CachedNetworkImage(
                              imageUrl: primaryImage,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surface,
                                child: const Icon(LucideIcons.image,
                                    color: AppColors.textSecondary),
                              ),
                            )
                          : Container(
                              color: AppColors.surface,
                              child: const Icon(LucideIcons.image,
                                  color: AppColors.textSecondary),
                            ),
                    ),
                    // Badge: show image count if >1
                    if (images.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.image,
                                  size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text('${images.length}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),


          // Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailScreen(vendorId: product.vendorId))),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.store, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          product.vendorName ?? 'View Store',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.discountPrice != null) ...[
                          Text(
                            '₹${product.basePrice.toInt()}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '₹${product.discountPrice!.toInt()}',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ] else
                          Text(
                            '₹${product.basePrice.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                      ],
                    ),
                    if (cartQty > 0)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.minusCircle, size: 18),
                            onPressed: () => context.read<MarketplaceBloc>().add(RemoveFromCart(product.id)),
                          ),
                          Text('$cartQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(LucideIcons.plusCircle, size: 18, color: AppColors.primary),
                            onPressed: () => context.read<MarketplaceBloc>().add(AddToCart(product)),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.read<MarketplaceBloc>().add(AddToCart(product)),
                        child: const Text('ADD', style: TextStyle(fontSize: 11, color: Colors.black)),
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

  void _openProductDetail(ProductModel product) async {
    final openCart = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    if (openCart == true && mounted) {
      _showCartDrawer(context);
    }
  }

  void _showCartDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            if (state is! ProductsLoaded) return const SizedBox.shrink();

            final cartProducts = state.products.where((p) => state.cart.containsKey(p.id)).toList();
            double subTotal = 0.0;
            for (var p in cartProducts) {
              subTotal += (p.discountPrice ?? p.basePrice) * state.cart[p.id]!;
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SHOPPING CART', style: Theme.of(context).textTheme.titleLarge),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                            onPressed: () {
                              context.read<MarketplaceBloc>().add(ClearCart());
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Items List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: cartProducts.length,
                          itemBuilder: (context, index) {
                            final p = cartProducts[index];
                            final qty = state.cart[p.id]!;
                            return ListTile(
                              leading: CachedNetworkImage(
                                imageUrl: p.imageUrl ?? '',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (c, _, __) => const Icon(LucideIcons.package),
                              ),
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('₹${(p.discountPrice ?? p.basePrice).toInt()} x $qty'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.minusSquare),
                                    onPressed: () => context.read<MarketplaceBloc>().add(RemoveFromCart(p.id)),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.plusSquare, color: AppColors.primary),
                                    onPressed: () => context.read<MarketplaceBloc>().add(AddToCart(p)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Bill Details
                      const Divider(color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('₹${subTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping:'),
                          const Text('₹50', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Promo entry
                      TextField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Promo Code (e.g. WAX10)',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      ElevatedButton(
                        onPressed: () async {
                          final address = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
                          );
                          if (address != null && context.mounted) {
                            final addressId = address['id'] as String;
                            context.read<MarketplaceBloc>().add(
                              PlaceOrder(
                                vendorId: cartProducts.first.vendorId,
                                shippingAddressId: addressId,
                                couponCode: _couponController.text.isNotEmpty ? _couponController.text : null,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: Text('PLACE ORDER (₹${(subTotal + 50).toInt()})'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
