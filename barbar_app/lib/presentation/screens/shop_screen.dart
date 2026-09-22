import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../domain/repositories/directory_repository.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';
import 'order_history_screen.dart';
import 'select_address_screen.dart';
import 'checkout_screen.dart';
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
  String _selectedPaymentMethod = 'cod';

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
            final authState = context.read<AuthBloc>().state;
            final isBarber = authState is AuthAuthenticated && authState.user.role == 'barber';
            return Column(
              children: [
                if (isBarber)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.star, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Professional Pricing Active',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                              Text('You are seeing exclusive business pricing.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final authState = context.read<AuthBloc>().state;
    final isBarber = authState is AuthAuthenticated && authState.user.role == 'barber';
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
                    // Badge: PRO badge for professional products
                    if (isBarber && product.hasProfessionalPrice)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('PRO',
                              style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isBarber && product.hasProfessionalPrice) ...[
                            Text(
                              '₹${product.basePrice.toInt()}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Professional ₹${product.professionalPrice!.toInt()}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Save ₹${(product.basePrice - product.professionalPrice!).toInt()}',
                                    style: const TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (product.professionalMoq > 1) ...[
                                  const SizedBox(width: 4),
                                  Text('MOQ: ${product.professionalMoq}',
                                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ] else if (product.hasDiscount) ...[
                            Text(
                              '₹${product.basePrice.toInt()}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '₹${product.displayPrice.toInt()}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                          ] else
                            Text(
                              '₹${product.displayPrice.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                        ],
                      ),
                    ),
                    if (cartQty > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                        onPressed: () {
                          if (isBarber && product.hasProfessionalPrice && product.professionalMoq > 1) {
                            context.read<MarketplaceBloc>().add(AddToCart(product, quantity: product.professionalMoq));
                          } else {
                            context.read<MarketplaceBloc>().add(AddToCart(product));
                          }
                        },
                        child: Text(
                          isBarber && product.hasProfessionalPrice && product.professionalMoq > 1
                              ? 'ADD ${product.professionalMoq}'
                              : 'ADD',
                          style: const TextStyle(fontSize: 11, color: Colors.black),
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
    final authState = context.read<AuthBloc>().state;
    final isBarber = authState is AuthAuthenticated && authState.user.role == 'barber';

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
            double retailTotal = 0.0;
            bool hasMoqViolation = false;
            for (var p in cartProducts) {
              final qty = state.cart[p.id]!;
              subTotal += p.getActivePrice(isBarber) * qty;
              retailTotal += p.basePrice * qty;
              if (isBarber && p.hasProfessionalPrice && qty < p.professionalMoq) {
                hasMoqViolation = true;
              }
            }
            final savings = retailTotal - subTotal;
            final double shipping = (subTotal >= 299 || isBarber) ? 0.0 : 49.0;
            final double totalPayable = subTotal + shipping;

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
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
                          Text(isBarber ? 'PROFESSIONAL CART' : 'SHOPPING CART', style: Theme.of(context).textTheme.titleLarge),
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
                            final belowMoq = isBarber && p.hasProfessionalPrice && qty < p.professionalMoq;
                            return Column(
                              children: [
                                ListTile(
                                  leading: CachedNetworkImage(
                                    imageUrl: p.imageUrl ?? '',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, _, __) => const Icon(LucideIcons.package),
                                  ),
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isBarber && p.hasProfessionalPrice
                                          ? 'Professional: ₹${p.getActivePrice(isBarber).toInt()} x $qty'
                                          : '₹${p.getActivePrice(isBarber).toInt()} x $qty'),
                                      if (isBarber && p.hasProfessionalPrice)
                                        Text('Retail MRP: ₹${p.basePrice.toInt()} each',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                                    ],
                                  ),
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
                                ),
                                if (belowMoq)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 72, bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.alertTriangle, size: 14, color: AppColors.error),
                                        const SizedBox(width: 4),
                                        Text('Minimum order quantity is ${p.professionalMoq}.',
                                            style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      
                      // Bill Details
                      const Divider(color: AppColors.border),
                      if (savings > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Retail Total (MRP):', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            Text('₹${retailTotal.toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isBarber ? 'Professional Discount:' : 'Discount Savings:', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('-₹${savings.toInt()}', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discounted Subtotal:'),
                          Text('₹${subTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Charges:'),
                          if (shipping == 0)
                            Row(
                              children: [
                                const Text('₹50', style: TextStyle(color: AppColors.textMuted, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('FREE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            )
                          else
                            Text('₹${shipping.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (savings > 0 || shipping == 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '🎉 Total savings on this order: ₹${(savings + (shipping == 0 ? 50 : 0)).toInt()}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      
                      // Promo entry
                      TextField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Promo Code (e.g. WAX10)',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ElevatedButton(
                        onPressed: hasMoqViolation
                            ? null
                            : () async {
                          final address = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(builder: (_) => const SelectAddressScreen()),
                          );
                          if (address != null && context.mounted) {
                            final success = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  address: address,
                                  subTotal: subTotal,
                                  vendorId: cartProducts.first.vendorId,
                                  couponCode: _couponController.text.isNotEmpty ? _couponController.text : null,
                                ),
                              ),
                            );
                            if (success == true && context.mounted) {
                              Navigator.pop(context); // Close cart sheet
                            }
                          }
                        },
                        child: Text(hasMoqViolation
                            ? 'MINIMUM ORDER QUANTITY NOT MET'
                            : 'PLACE ORDER (₹${totalPayable.toInt()})'),
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
