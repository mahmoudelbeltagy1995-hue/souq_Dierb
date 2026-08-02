import '../../domain/entities/service_area_entity.dart';

class ServiceAreaModel extends ServiceAreaEntity {
  const ServiceAreaModel({required super.id,required super.nameAr,super.nameEn,required super.deliveryFee,
    required super.minimumOrder,required super.estimatedDeliveryMinutes});
  factory ServiceAreaModel.fromJson(Map<String,dynamic> json) => ServiceAreaModel(
    id: json['id'] as String,nameAr: json['name_ar'] as String,nameEn: json['name_en'] as String?,
    deliveryFee: (json['delivery_fee'] as num).toDouble(),minimumOrder: (json['minimum_order'] as num).toDouble(),
    estimatedDeliveryMinutes: json['estimated_delivery_minutes'] as int);
}
