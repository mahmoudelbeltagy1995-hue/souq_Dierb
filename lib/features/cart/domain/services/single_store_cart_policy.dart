class CartStoreConflict implements Exception {
  const CartStoreConflict();
}

abstract final class SingleStoreCartPolicy {
  static bool canAdd({String? currentStoreId,required String candidateStoreId}) =>
    currentStoreId==null || currentStoreId==candidateStoreId;
}
