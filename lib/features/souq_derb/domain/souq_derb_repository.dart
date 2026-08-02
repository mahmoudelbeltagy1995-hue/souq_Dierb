import 'models.dart';

abstract class SouqDerbRepository {
  bool get isDemo;
  Future<void> initialize();
  Future<AppUser?> currentUser();
  Future<AppUser> signIn(String email,String password);
  Future<AppUser> registerCustomer({required String name,required String phone,required String email,
    required String password,required String serviceAreaId});
  Future<AppUser> registerMerchant(MerchantRegistration registration);
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<List<ServiceArea>> areas();
  Future<List<StoreCategory>> storeCategories();
  Future<List<StoreData>> stores({required String areaId,String? categoryId,String query='',bool openOnly=false});
  Future<StoreData?> store(String id);
  Future<List<ProductData>> products(String storeId,{String query=''});
  Future<List<CustomerAddress>> addresses();
  Future<CustomerAddress> addAddress(CustomerAddress address);
  Future<List<CartLine>> cart();
  Future<void> saveCart(List<CartLine> lines);
  Future<OrderData> checkout({required String storeId,required CustomerAddress address,
    required List<CartLine> lines,required String idempotencyKey,String? note});
  Future<List<OrderData>> customerOrders();
  Future<List<OrderData>> merchantOrders(String storeId);
  Future<OrderData> transitionOrder(String orderId,OrderStatus status,{String? reason});
  Future<StoreData?> merchantStore();
  Future<StoreData> updateStore(StoreData store);
  Future<List<ProductData>> merchantProducts(String storeId);
  Future<ProductData> saveProduct(ProductData product);
  Future<void> deleteProduct(String productId);
  Future<List<StoreData>> storeApplications();
  Future<StoreData> reviewStore(String storeId,StoreApproval status,{String? reason});
  Future<StoreData> setSubscription(String storeId,SubscriptionStatus status);
}

class RepositoryException implements Exception {
  final String message; const RepositoryException(this.message);
  @override String toString()=>message;
}
