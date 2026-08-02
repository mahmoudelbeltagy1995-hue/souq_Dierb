import 'package:dartz/dartz.dart';

class CheckoutItemInput {
  final String productId; final int quantity; final List<String> optionIds; final String? notes;
  const CheckoutItemInput({required this.productId,required this.quantity,this.optionIds=const [],this.notes});
  Map<String,dynamic> toJson()=>{'product_id':productId,'quantity':quantity,'option_ids':optionIds,'notes':notes};
}
class CheckoutResult {
  final String orderId; final int orderNumber; final double totalAmount;
  const CheckoutResult({required this.orderId,required this.orderNumber,required this.totalAmount});
}
abstract class SecureCheckoutRepository {
  Future<Either<String,CheckoutResult>> placeOrder({required String storeId,required String addressId,
    required List<CheckoutItemInput> items,required String idempotencyKey,String? customerNote});
}
