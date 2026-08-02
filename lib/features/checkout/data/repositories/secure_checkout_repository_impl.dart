import 'package:dartz/dartz.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/repositories/secure_checkout_repository.dart';

class SecureCheckoutRepositoryImpl implements SecureCheckoutRepository {
  final SupabaseService supabaseService;
  SecureCheckoutRepositoryImpl({required this.supabaseService});
  @override Future<Either<String,CheckoutResult>> placeOrder({required String storeId,required String addressId,
      required List<CheckoutItemInput> items,required String idempotencyKey,String? customerNote}) async {
    if(items.isEmpty) return const Left('السلة فارغة');
    try {
      final json=await supabaseService.client.rpc('create_souq_order',params:{
        'p_store_id':storeId,'p_address_id':addressId,'p_items':items.map((e)=>e.toJson()).toList(),
        'p_idempotency_key':idempotencyKey,'p_customer_note':customerNote,
      }) as Map<String,dynamic>;
      return Right(CheckoutResult(orderId:json['order_id'] as String,orderNumber:(json['order_number'] as num).toInt(),
        totalAmount:(json['total_amount'] as num).toDouble()));
    } catch (error) { return Left(_message(error.toString())); }
  }
  String _message(String error) {
    if(error.contains('minimum_order_not_met')) return 'لم تصل قيمة الطلب إلى الحد الأدنى للمتجر';
    if(error.contains('insufficient_stock')) return 'الكمية المطلوبة غير متوفرة';
    if(error.contains('store_unavailable')) return 'المتجر مغلق أو لا يخدم منطقتك حاليًا';
    if(error.contains('product_unavailable')||error.contains('option_unavailable')) return 'أحد المنتجات أو الخيارات لم يعد متاحًا';
    return 'تعذر إرسال الطلب. تحقق من الاتصال وحاول مرة أخرى.';
  }
}
