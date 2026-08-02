import 'package:dartz/dartz.dart';
import '../entities/service_area_entity.dart';
import '../entities/store_entity.dart';

abstract class MarketplaceRepository {
  Future<Either<String,List<ServiceAreaEntity>>> getServiceAreas();
  Future<Either<String,List<StoreEntity>>> getStores({required String serviceAreaId,String? categoryId,int page=0,int pageSize=20});
}
