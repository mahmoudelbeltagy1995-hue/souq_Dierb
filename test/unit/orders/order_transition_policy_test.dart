import 'package:flutter_test/flutter_test.dart';
import 'package:t_store/features/orders/domain/services/order_transition_policy.dart';

void main(){
  test('merchant follows sequential order journey',(){
    expect(OrderTransitionPolicy.canMerchantTransition(SouqOrderStatus.pending,SouqOrderStatus.accepted),isTrue);
    expect(OrderTransitionPolicy.canMerchantTransition(SouqOrderStatus.pending,SouqOrderStatus.delivered),isFalse);
    expect(OrderTransitionPolicy.canMerchantTransition(SouqOrderStatus.ready,SouqOrderStatus.outForDelivery),isTrue);
  });
  test('customer can only cancel a pending order',(){
    expect(OrderTransitionPolicy.canCustomerCancel(SouqOrderStatus.pending),isTrue);
    expect(OrderTransitionPolicy.canCustomerCancel(SouqOrderStatus.preparing),isFalse);
  });
}
