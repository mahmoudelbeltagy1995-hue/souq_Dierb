import 'package:flutter_test/flutter_test.dart';
import 'package:t_store/features/cart/domain/services/single_store_cart_policy.dart';

void main(){
  test('allows first product and same-store products',(){
    expect(SingleStoreCartPolicy.canAdd(currentStoreId:null,candidateStoreId:'a'),isTrue);
    expect(SingleStoreCartPolicy.canAdd(currentStoreId:'a',candidateStoreId:'a'),isTrue);
  });
  test('rejects a second store',()=>expect(
    SingleStoreCartPolicy.canAdd(currentStoreId:'a',candidateStoreId:'b'),isFalse));
}
