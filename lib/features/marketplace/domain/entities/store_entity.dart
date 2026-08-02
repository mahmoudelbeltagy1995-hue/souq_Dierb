import 'package:equatable/equatable.dart';

class StoreEntity extends Equatable {
  final String id; final String ownerId; final String categoryId; final String nameAr;
  final String? description; final String? logoUrl; final String? coverUrl; final String phone;
  final String? whatsapp; final String address; final bool isOpen; final double minimumOrder;
  final double deliveryFee; final int estimatedDeliveryMinutes; final double averageRating;

  const StoreEntity({required this.id,required this.ownerId,required this.categoryId,required this.nameAr,
    this.description,this.logoUrl,this.coverUrl,required this.phone,this.whatsapp,required this.address,
    required this.isOpen,required this.minimumOrder,required this.deliveryFee,
    required this.estimatedDeliveryMinutes,required this.averageRating});

  @override List<Object?> get props => [id,ownerId,categoryId,nameAr,description,logoUrl,coverUrl,phone,
    whatsapp,address,isOpen,minimumOrder,deliveryFee,estimatedDeliveryMinutes,averageRating];
}
