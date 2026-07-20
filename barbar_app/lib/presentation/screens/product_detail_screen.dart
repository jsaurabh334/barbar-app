import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../bloc/marketplace/marketplace_bloc.dart';
import '../bloc/marketplace/marketplace_event.dart';
import '../bloc/marketplace/marketplace_state.dart';
import 'vendor_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images ?? (widget.product.imageUrl != null ? [widget.product.imageUrl!] : <String>[]);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          BlocBuilder<MarketplaceBloc, MarketplaceState>(
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
                    onPressed: cartCount > 0 ? () => Navigator.pop(context, true) : null,
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
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                if (images.isNotEmpty)
                  SizedBox(
                    height: 350,
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'product_img_${widget.product.id}',
                          child: PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _currentIndex = i),
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: images[i],
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.cardBg,
                                child: const Icon(LucideIcons.image, size: 60, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (i) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _currentIndex ? 18 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _currentIndex ? AppColors.primary : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),
                        if (images.length > 1)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / ${images.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.product.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                widget.product.categoryName!.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          if (widget.product.rating > 0)
                            Row(
                              children: [
                                const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${widget.product.rating.toStringAsFixed(1)} (${widget.product.reviewCount} reviews)',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Name
                      Text(widget.product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                      const SizedBox(height: 8),
                      
                      // Brand
                      if (widget.product.brand != null && widget.product.brand!.isNotEmpty)
                        Text('By ${widget.product.brand}', style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      
                      // Price section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.product.discountPrice != null) ...[
                            Text('₹${widget.product.discountPrice!.toInt()}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 28)),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('₹${widget.product.basePrice.toInt()}',
                                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.textMuted, fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '${(((widget.product.basePrice - widget.product.discountPrice!) / widget.product.basePrice) * 100).toInt()}% OFF',
                                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ] else
                            Text('₹${widget.product.basePrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Availability & Tags
                      Row(
                        children: [
                          Icon(
                            widget.product.outOfStock ? LucideIcons.xCircle : LucideIcons.checkCircle2,
                            size: 16,
                            color: widget.product.outOfStock ? AppColors.error : AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.product.outOfStock
                                ? 'Out of Stock'
                                : widget.product.isLowStock
                                    ? 'Only ${widget.product.availableStock} left in stock'
                                    : 'In Stock',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.product.outOfStock
                                  ? AppColors.error
                                  : widget.product.isLowStock
                                      ? AppColors.warning
                                      : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      
                      if (widget.product.tags != null && widget.product.tags!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.product.tags!.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      
                      // Vendor Section
                      GestureDetector(
                        onTap: () {
                          if (widget.product.vendorId.isNotEmpty) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailScreen(vendorId: widget.product.vendorId)));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.store, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sold by', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    Text(
                                      widget.product.vendorName ?? 'Grooming Store',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Delivery & Services
                      const Text('Delivery & Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildServiceItem(LucideIcons.truck, 'Free Delivery', 'Usually delivered in 3-5 days'),
                      const SizedBox(height: 12),
                      _buildServiceItem(LucideIcons.shieldCheck, 'Authentic Product', '100% genuine product guarantee'),
                      const SizedBox(height: 12),
                      _buildServiceItem(LucideIcons.rotateCcw, '7 Days Return', 'Easy return policy if damaged'),
                      
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),

                      // Description
                      const Text('Product Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(widget.product.description, style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
              builder: (context, state) {
                final cart = state is ProductsLoaded ? state.cart : <String, int>{};
                final qty = cart[widget.product.id] ?? 0;

                return Row(
                  children: [
                    if (qty > 0)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.read<MarketplaceBloc>().add(RemoveFromCart(widget.product.id)),
                              icon: const Icon(LucideIcons.minus),
                            ),
                            Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () => context.read<MarketplaceBloc>().add(AddToCart(widget.product)),
                              icon: const Icon(LucideIcons.plus, color: AppColors.primary),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<MarketplaceBloc>().add(AddToCart(widget.product));
                          },
                          icon: const Icon(LucideIcons.shoppingCart, size: 18),
                          label: const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (qty == 0) {
                            context.read<MarketplaceBloc>().add(AddToCart(widget.product));
                          }
                          Navigator.pop(context, true); // true indicates open cart
                        },
                        icon: const Icon(LucideIcons.zap, size: 18, color: Colors.black),
                        label: const Text('ORDER NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
