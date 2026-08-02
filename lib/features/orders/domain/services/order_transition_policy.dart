enum SouqOrderStatus { pending, accepted, preparing, ready, outForDelivery, delivered, cancelled, rejected }

abstract final class OrderTransitionPolicy {
  static const Map<SouqOrderStatus,Set<SouqOrderStatus>> _merchantTransitions = {
    SouqOrderStatus.pending:{SouqOrderStatus.accepted,SouqOrderStatus.rejected},
    SouqOrderStatus.accepted:{SouqOrderStatus.preparing},
    SouqOrderStatus.preparing:{SouqOrderStatus.ready},
    SouqOrderStatus.ready:{SouqOrderStatus.outForDelivery},
    SouqOrderStatus.outForDelivery:{SouqOrderStatus.delivered},
  };
  static bool canMerchantTransition(SouqOrderStatus from,SouqOrderStatus to) =>
    _merchantTransitions[from]?.contains(to) ?? false;
  static bool canCustomerCancel(SouqOrderStatus from) => from==SouqOrderStatus.pending;
}
