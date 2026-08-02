import '../../domain/entities/store_entity.dart';

class StoreModel extends StoreEntity {
  const StoreModel({required super.id,required super.ownerId,required super.categoryId,required super.nameAr,
    super.description,super.logoUrl,super.coverUrl,required super.phone,super.whatsapp,required super.address,
    required super.isOpen,required super.minimumOrder,required super.deliveryFee,
    required super.estimatedDeliveryMinutes,required super.averageRating});
  factory StoreModel.fromJson(Map<String,dynamic> json) => StoreModel(
    id:json['id'] as String,ownerId:json['owner_id'] as String,categoryId:json['category_id'] as String,
    nameAr:json['name_ar'] as String,description:json['description'] as String?,logoUrl:json['logo_url'] as String?,
    coverUrl:json['cover_url'] as String?,phone:json['phone'] as String,whatsapp:json['whatsapp'] as String?,
    address:json['address'] as String,isOpen:json['is_open_manual'] as bool? ?? false,
    minimumOrder:(json['minimum_order'] as num).toDouble(),deliveryFee:(json['delivery_fee'] as num).toDouble(),
    estimatedDeliveryMinutes:json['estimated_delivery_minutes'] as int,
    averageRating:(json['average_rating'] as num?)?.toDouble() ?? 0);
}
