import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    on<CancelOrder>(_onCancelOrder);
    on<SubmitReturnRequest>(_onSubmitReturnRequest);
    on<ReportIssue>(_onReportIssue);
    on<InitiateOrderPayment>(_onInitiateOrderPayment);
    on<VerifyOrderPayment>(_onVerifyOrderPayment);
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('marketplace_cart');
      if (cartJson != null) {
        final decoded = jsonDecode(cartJson) as Map<String, dynamic>;
        _cart.clear();
        decoded.forEach((key, value) => _cart[key] = value as int);
      }
    } catch (_) {}
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('marketplace_cart', jsonEncode(_cart));
    } catch (_) {}
  }

  Future<void> _onFetchProducts(FetchProducts event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      _cachedProducts = await _marketplaceRepository.getProducts();
      emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onAddToCart(AddToCart event, Emitter<MarketplaceState> emit) {
    final currentQty = _cart[event.product.id] ?? 0;
    _cart[event.product.id] = currentQty + event.quantity;
    _saveCart();
    emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<MarketplaceState> emit) {
    final currentQty = _cart[event.productId] ?? 0;
    if (currentQty > 1) {
      _cart[event.productId] = currentQty - 1;
    } else {
      _cart.remove(event.productId);
    }
    _saveCart();
    emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
  }

  void _onClearCart(ClearCart event, Emitter<MarketplaceState> emit) {
    _cart.clear();
    _saveCart();
    emit(ProductsLoaded(products: List.from(_cachedProducts), cart: Map.from(_cart)));
  }

  Map<String, int> getCart() => Map.from(_cart);

  Future<void> _onPlaceOrder(PlaceOrder event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      final items = _cart.entries.map((e) => {
        'product_id': e.key,
        'quantity': e.value,
      }).toList();

      final order = await _marketplaceRepository.placeOrder(
        vendorId: event.vendorId,
        shippingAddressId: event.shippingAddressId,
        couponCode: event.couponCode,
        items: items,
        paymentMethod: event.paymentMethod,
      );
      _cart.clear();
      _saveCart();
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

  Future<void> _onCancelOrder(CancelOrder event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _marketplaceRepository.cancelOrder(event.orderId, reason: event.reason);
      final orders = await _marketplaceRepository.getOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSubmitReturnRequest(SubmitReturnRequest event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _marketplaceRepository.submitReturnRequest(
        event.orderId,
        reason: event.reason,
        images: event.images,
      );
      final orders = await _marketplaceRepository.getOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onReportIssue(ReportIssue event, Emitter<MarketplaceState> emit) async {
    try {
      await _marketplaceRepository.reportIssue(
        event.orderId,
        issueType: event.issueType,
        description: event.description,
      );
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onInitiateOrderPayment(InitiateOrderPayment event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      final paymentData = await _marketplaceRepository.initiatePayment(event.orderId, gateway: event.gateway);
      emit(PaymentInitiated(paymentData));
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onVerifyOrderPayment(VerifyOrderPayment event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _marketplaceRepository.verifyPayment(
        paymentId: event.paymentId,
        gateway: event.gateway,
        razorpayOrderId: event.razorpayOrderId,
        razorpayPaymentId: event.razorpayPaymentId,
        razorpaySignature: event.razorpaySignature,
      );
      emit(const PaymentVerificationSuccess());
    } catch (e) {
      emit(MarketplaceFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
