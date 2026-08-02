import 'package:equatable/equatable.dart';

class ServiceAreaEntity extends Equatable {
  final String id;
  final String nameAr;
  final String? nameEn;
  final double deliveryFee;
  final double minimumOrder;
  final int estimatedDeliveryMinutes;

  const ServiceAreaEntity({required this.id, required this.nameAr, this.nameEn,
    required this.deliveryFee, required this.minimumOrder, required this.estimatedDeliveryMinutes});

  @override List<Object?> get props => [id,nameAr,nameEn,deliveryFee,minimumOrder,estimatedDeliveryMinutes];
}
