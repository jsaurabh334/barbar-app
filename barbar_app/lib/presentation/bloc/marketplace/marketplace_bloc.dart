import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/repositories/marketplace_repository.dart';
import 'marketplace_event.dart';
import 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final MarketplaceRepository _marketplaceRepository;

  final Map<String, int> _cart = {};
  List<ProductModel> _cachedProducts = [];

  MarketplaceBloc(this._marketplaceRepository) : super(MarketplaceInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<PlaceOrder>(_onPlaceOrder);
    on<FetchAllOrders>(_onFetchAllOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
  }

  Future<void> _onFetchProducts(FetchProducts event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _marketplaceRepository.getProducts();
      _cachedProducts = await _marketplaceRepository.getProducts();
      emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onAddToCart(AddToCart event, Emitter<MarketplaceState> emit) {
    final currentQty = _cart[event.product.id] ?? 0;
    _cart[event.product.id] = currentQty + 1;
    emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<MarketplaceState> emit) {
    final currentQty = _cart[event.productId] ?? 0;
    if (currentQty > 1) {
      _cart[event.productId] = currentQty - 1;
    } else {
      _cart.remove(event.productId);
    }
    emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
  }

  void _onClearCart(ClearCart event, Emitter<MarketplaceState> emit) {
    _cart.clear();
    emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
  }

  Future<void> _onPlaceOrder(PlaceOrder event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      final order = await _marketplaceRepository.placeOrder(
        vendorId: event.vendorId,
        shippingAddressId: event.shippingAddressId,
        couponCode: event.couponCode,
      );
      _cart.clear();
      emit(OrderCreatedSuccess(order));
      emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchAllOrders(FetchAllOrders event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      final orders = await _marketplaceRepository.getOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _marketplaceRepository.updateOrderStatus(event.orderId, event.status);
      final orders = await _marketplaceRepository.getOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
