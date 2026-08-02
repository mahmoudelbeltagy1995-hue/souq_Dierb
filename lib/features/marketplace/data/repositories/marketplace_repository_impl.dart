import 'package:dartz/dartz.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/supabase/supabase_tables.dart';
import '../../domain/entities/service_area_entity.dart';
import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../models/service_area_model.dart';
import '../models/store_model.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final SupabaseService supabaseService;
  MarketplaceRepositoryImpl({required this.supabaseService});

  @override Future<Either<String,List<ServiceAreaEntity>>> getServiceAreas() async {
    try {
      final rows=await supabaseService.client.from(SupabaseTables.serviceAreas).select()
        .eq('is_active',true).order('sort_order');
      return Right(rows.map<ServiceAreaEntity>((e)=>ServiceAreaModel.fromJson(e)).toList());
    } catch (_) { return const Left('تعذر تحميل مناطق الخدمة. حاول مرة أخرى.'); }
  }

  @override Future<Either<String,List<StoreEntity>>> getStores({required String serviceAreaId,
      String? categoryId,int page=0,int pageSize=20}) async {
    try {
      final links=await supabaseService.client.from(SupabaseTables.storeServiceAreas)
        .select('stores(*)').eq('service_area_id',serviceAreaId).eq('is_active',true)
        .range(page*pageSize,(page+1)*pageSize-1);
      var stores=links.map<StoreEntity>((e)=>StoreModel.fromJson(e['stores'] as Map<String,dynamic>)).toList();
      if(categoryId!=null) stores=stores.where((s)=>s.categoryId==categoryId).toList();
      return Right(stores);
    } catch (_) { return const Left('تعذر تحميل المحلات. تحقق من الاتصال وحاول مجددًا.'); }
  }
}
