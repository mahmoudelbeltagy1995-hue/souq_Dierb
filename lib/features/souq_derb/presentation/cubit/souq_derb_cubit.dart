import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models.dart';
import '../../domain/souq_derb_repository.dart';
import 'souq_derb_state.dart';

class SouqDerbCubit extends Cubit<SouqDerbState> {
  final SouqDerbRepository repository;
  SouqDerbCubit(this.repository):super(const SouqDerbState());

  Future<void> bootstrap() async {
    try {
      await repository.initialize();
      final areas = await repository.areas();
      final user = await repository.currentUser();
      emit(state.copyWith(booting: false, areas: areas, user: user, selectedAreaId: user?.serviceAreaId ?? areas.firstOrNull?.id));
      if (user != null) await refreshForRole();
    } catch (e) {
      emit(state.copyWith(booting: false, error: _message(e)));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await action();
      emit(state.copyWith(busy: false));
    } catch (e) {
      emit(state.copyWith(busy: false, error: _message(e)));
    }
  }

  String _message(Object e) => e is RepositoryException ? e.message : e.toString().replaceFirst('Exception: ', '');
  void clearError() => emit(state.copyWith(clearError: true));
  Future<void> signIn(String email, String password) => _run(() async {
    final u = await repository.signIn(email, password);
    emit(state.copyWith(user: u, selectedAreaId: u.serviceAreaId));
    await refreshForRole();
  });
  Future<void> registerCustomer({required String name, required String phone, required String email, required String password, required String areaId}) => _run(() async {
    final u = await repository.registerCustomer(name: name, phone: phone, email: email, password: password, serviceAreaId: areaId);
    emit(state.copyWith(user: u, selectedAreaId: areaId));
    await refreshForRole();
  });
  Future<void> registerMerchant(MerchantRegistration registration) => _run(() async {
    final u = await repository.registerMerchant(registration);
    final store = await repository.merchantStore();
    emit(state.copyWith(user: u, selectedAreaId: u.serviceAreaId, merchantStore: store));
  });
  Future<void> resetPassword(String email) => _run(() async => repository.resetPassword(email));
  Future<void> signOut() => _run(() async {
    await repository.signOut();
    emit(state.copyWith(clearUser: true, cart: const [], orders: const [], stores: const [], clearMerchantStore: true));
  });

  Future<void> refreshForRole() async {
    final u = state.user;
    if (u == null) return;
    switch (u.role) {
      case AppRole.customer:
        await refreshCustomer();
        break;
      case AppRole.merchant:
        final store = await repository.merchantStore();
        emit(state.copyWith(merchantStore: store));
        if (store != null) {
          emit(state.copyWith(orders: await repository.merchantOrders(store.id)));
        }
        break;
      case AppRole.admin:
        emit(state.copyWith(stores: await repository.storeApplications()));
        break;
      case AppRole.staff:
      case AppRole.driver:
        break;
    }
  }

  Future<void> refreshCustomer({String? categoryId, String query = '', bool openOnly = false}) async {
    final area = state.selectedAreaId;
    if (area == null) return;
    final results = await Future.wait([
      repository.storeCategories(),
      repository.stores(areaId: area, categoryId: categoryId, query: query, openOnly: openOnly),
      repository.cart(),
      repository.customerOrders()
    ]);
    emit(state.copyWith(
      categories: results[0] as List<StoreCategory>,
      stores: results[1] as List<StoreData>,
      cart: results[2] as List<CartLine>,
      orders: results[3] as List<OrderData>,
    ));
  }

  Future<void> changeArea(String id) async {
    emit(state.copyWith(selectedAreaId: id));
    await refreshCustomer();
  }

  Future<List<ProductData>> products(String storeId, {String query = ''}) => repository.products(storeId, query: query);
  Future<StoreData?> getStore(String id) => repository.store(id);
  Future<List<CustomerAddress>> addresses() => repository.addresses();
  Future<CustomerAddress> addAddress(CustomerAddress address) => repository.addAddress(address);

  Future<bool> addToCart(CartLine line, {bool replace = false}) async {
    final existingStore = state.cartStoreId;
    if (existingStore != null && existingStore != line.product.storeId && !replace) {
      return false;
    }
    final lines = replace ? [line] : (List<CartLine>.from(state.cart)..add(line));
    await repository.saveCart(lines);
    emit(state.copyWith(cart: lines));
    return true;
  }

  Future<void> updateQuantity(int index, int quantity) async {
    final lines = List<CartLine>.from(state.cart);
    if (quantity <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(quantity: quantity);
    }
    await repository.saveCart(lines);
    emit(state.copyWith(cart: lines));
  }

  Future<void> clearCart() async {
    await repository.saveCart([]);
    emit(state.copyWith(cart: const []));
  }

  Future<OrderData?> checkout({required CustomerAddress address, String? note}) async {
    OrderData? order;
    await _run(() async {
      if (state.cart.isEmpty) {
        throw const RepositoryException('السلة فارغة');
      }
      final storeId = state.cartStoreId;
      if (storeId == null) {
        throw const RepositoryException('Store ID not found');
      }
      order = await repository.checkout(
        storeId: storeId,
        address: address,
        lines: state.cart,
        idempotencyKey: '${state.user!.id}-${DateTime.now().microsecondsSinceEpoch}',
        note: note,
      );
      await repository.saveCart([]);
      emit(state.copyWith(cart: const []));
    });
    return order;
  }

  Future<void> transitionOrder(String id, OrderStatus status, {String? reason}) => _run(() async {
    await repository.transitionOrder(id, status, reason: reason);
    await refreshForRole();
  });

  Future<List<ProductData>> merchantProducts() => repository.merchantProducts(state.merchantStore!.id);
  Future<void> saveProduct(ProductData p) => _run(() async {
    await repository.saveProduct(p);
  });
  Future<void> deleteProduct(String id) => _run(() async => repository.deleteProduct(id));
  Future<void> updateStore(StoreData store) => _run(() async {
    final updated = await repository.updateStore(store);
    emit(state.copyWith(merchantStore: updated));
  });
  Future<void> reviewStore(String id, StoreApproval approval, {String? reason}) => _run(() async {
    await repository.reviewStore(id, approval, reason: reason);
    emit(state.copyWith(stores: await repository.storeApplications()));
  });
  Future<void> setSubscription(String id, SubscriptionStatus status) => _run(() async {
    await repository.setSubscription(id, status);
    emit(state.copyWith(stores: await repository.storeApplications()));
  });
}
