import '../../domain/models.dart';

class SouqDerbState {
  final bool booting,busy; final AppUser? user; final String? error,selectedAreaId;
  final List<ServiceArea> areas; final List<StoreCategory> categories; final List<StoreData> stores;
  final List<CartLine> cart; final List<OrderData> orders; final StoreData? merchantStore;
  const SouqDerbState({this.booting=true,this.busy=false,this.user,this.error,this.selectedAreaId,
    this.areas=const [],this.categories=const [],this.stores=const [],this.cart=const [],this.orders=const [],this.merchantStore});
  SouqDerbState copyWith({bool? booting,bool? busy,AppUser? user,bool clearUser=false,String? error,
    bool clearError=false,String? selectedAreaId,List<ServiceArea>? areas,List<StoreCategory>? categories,
    List<StoreData>? stores,List<CartLine>? cart,List<OrderData>? orders,StoreData? merchantStore,
    bool clearMerchantStore=false})=>SouqDerbState(booting:booting??this.booting,busy:busy??this.busy,
      user:clearUser?null:user??this.user,error:clearError?null:error??this.error,
      selectedAreaId:selectedAreaId??this.selectedAreaId,areas:areas??this.areas,categories:categories??this.categories,
      stores:stores??this.stores,cart:cart??this.cart,orders:orders??this.orders,
      merchantStore:clearMerchantStore?null:merchantStore??this.merchantStore);
  double get cartSubtotal=>cart.fold(0,(sum,line)=>sum+line.total);
  String? get cartStoreId=>cart.isEmpty?null:cart.first.product.storeId;
}
