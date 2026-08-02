import 'dart:convert';

enum AppRole { customer, merchant, admin, staff, driver }
enum AccountStatus { active, pending, suspended, blocked }
enum StoreApproval { pending, approved, rejected, suspended }
enum SubscriptionStatus { trial, active, expired, suspended }
enum OrderStatus { pending, accepted, preparing, ready, outForDelivery, delivered, cancelled, rejected }

class AppUser {
  final String id, fullName, phone, email;
  final AppRole role; final AccountStatus status; final String? serviceAreaId;
  const AppUser({required this.id,required this.fullName,required this.phone,required this.email,
    required this.role,this.status=AccountStatus.active,this.serviceAreaId});
  Map<String,dynamic> toJson()=>{'id':id,'fullName':fullName,'phone':phone,'email':email,
    'role':role.name,'status':status.name,'serviceAreaId':serviceAreaId};
  factory AppUser.fromJson(Map<String,dynamic> j)=>AppUser(id:j['id'],fullName:j['fullName'],phone:j['phone'],
    email:j['email'],role:AppRole.values.byName(j['role']),status:AccountStatus.values.byName(j['status']),
    serviceAreaId:j['serviceAreaId']);
}

class ServiceArea {
  final String id,nameAr; final double deliveryFee,minimumOrder; final int minutes;
  const ServiceArea(this.id,this.nameAr,this.deliveryFee,this.minimumOrder,this.minutes);
}
class StoreCategory { final String id,name; final String icon; const StoreCategory(this.id,this.name,this.icon); }

class StoreData {
  final String id,ownerId,categoryId,name,description,phone,address,areaId;
  final String? whatsapp,logoUrl,coverUrl,rejectionReason;
  final List<String> serviceAreaIds; final bool isOpen,isActive; final double deliveryFee,minimumOrder,rating;
  final int deliveryMinutes,ratingsCount; final StoreApproval approval; final SubscriptionStatus subscription;
  const StoreData({required this.id,required this.ownerId,required this.categoryId,required this.name,
    required this.description,required this.phone,required this.address,required this.areaId,
    this.whatsapp,this.logoUrl,this.coverUrl,this.rejectionReason,this.serviceAreaIds=const [],this.isOpen=true,
    this.isActive=true,this.deliveryFee=20,this.minimumOrder=50,this.rating=0,this.deliveryMinutes=45,
    this.ratingsCount=0,this.approval=StoreApproval.pending,this.subscription=SubscriptionStatus.trial});
  bool get visible => approval==StoreApproval.approved && isActive &&
    (subscription==SubscriptionStatus.active||subscription==SubscriptionStatus.trial);
  StoreData copyWith({String? name,String? description,String? phone,String? address,String? whatsapp,
    List<String>? serviceAreaIds,bool? isOpen,double? deliveryFee,double? minimumOrder,int? deliveryMinutes,
    StoreApproval? approval,SubscriptionStatus? subscription,String? rejectionReason})=>StoreData(
      id:id,ownerId:ownerId,categoryId:categoryId,name:name??this.name,description:description??this.description,
      phone:phone??this.phone,address:address??this.address,areaId:areaId,whatsapp:whatsapp??this.whatsapp,
      logoUrl:logoUrl,coverUrl:coverUrl,rejectionReason:rejectionReason??this.rejectionReason,
      serviceAreaIds:serviceAreaIds??this.serviceAreaIds,isOpen:isOpen??this.isOpen,isActive:isActive,
      deliveryFee:deliveryFee??this.deliveryFee,minimumOrder:minimumOrder??this.minimumOrder,rating:rating,
      deliveryMinutes:deliveryMinutes??this.deliveryMinutes,ratingsCount:ratingsCount,
      approval:approval??this.approval,subscription:subscription??this.subscription);
}

class ProductOption { final String id,name; final double extra; final bool available;
  const ProductOption(this.id,this.name,{this.extra=0,this.available=true}); }
class ProductOptionGroup { final String id,name; final bool required,multiple; final List<ProductOption> options;
  const ProductOptionGroup(this.id,this.name,this.options,{this.required=false,this.multiple=false}); }
class ProductData {
  final String id,storeId,categoryId,name,description,unit; final double price; final double? compareAtPrice;
  final int stock; final bool available,featured; final String? imageUrl; final List<ProductOptionGroup> optionGroups;
  const ProductData({required this.id,required this.storeId,required this.categoryId,required this.name,
    required this.description,required this.price,this.compareAtPrice,this.stock=0,this.available=true,
    this.featured=false,this.imageUrl,this.unit='قطعة',this.optionGroups=const []});
  bool get inStock=>available&&stock>0;
  ProductData copyWith({String? name,String? description,double? price,double? compareAtPrice,int? stock,
    bool? available,bool? featured})=>ProductData(id:id,storeId:storeId,categoryId:categoryId,
      name:name??this.name,description:description??this.description,price:price??this.price,
      compareAtPrice:compareAtPrice??this.compareAtPrice,stock:stock??this.stock,
      available:available??this.available,featured:featured??this.featured,imageUrl:imageUrl,unit:unit,
      optionGroups:optionGroups);
}

class CartLine {
  final ProductData product; final int quantity; final List<ProductOption> options; final String note;
  const CartLine({required this.product,this.quantity=1,this.options=const [],this.note=''});
  double get unitTotal=>product.price+options.fold(0,(s,o)=>s+o.extra);
  double get total=>unitTotal*quantity;
  CartLine copyWith({int? quantity})=>CartLine(product:product,quantity:quantity??this.quantity,options:options,note:note);
  Map<String,dynamic> toJson()=>{'productId':product.id,'quantity':quantity,'optionIds':options.map((e)=>e.id).toList(),'note':note};
}
class CustomerAddress { final String id,title,name,phone,areaId,street,landmark; final bool isDefault;
  const CustomerAddress({required this.id,required this.title,required this.name,required this.phone,
    required this.areaId,required this.street,this.landmark='',this.isDefault=false}); }
class OrderLine { final String name; final int quantity; final double unitPrice; final List<ProductOption> options;
  const OrderLine(this.name,this.quantity,this.unitPrice,this.options); double get total=>(unitPrice+options.fold(0,(s,o)=>s+o.extra))*quantity; }
class OrderData {
  final String id,number,customerId,storeId,address; final List<OrderLine> items; final OrderStatus status;
  final double subtotal,deliveryFee,total; final DateTime createdAt; final String? reason,note;
  const OrderData({required this.id,required this.number,required this.customerId,required this.storeId,
    required this.address,required this.items,required this.status,required this.subtotal,
    required this.deliveryFee,required this.total,required this.createdAt,this.reason,this.note});
  OrderData copyWith({OrderStatus? status,String? reason})=>OrderData(id:id,number:number,customerId:customerId,
    storeId:storeId,address:address,items:items,status:status??this.status,subtotal:subtotal,
    deliveryFee:deliveryFee,total:total,createdAt:createdAt,reason:reason??this.reason,note:note);
}

class MerchantRegistration {
  final String ownerName,phone,email,password,storeName,categoryId,areaId,address,whatsapp,description;
  final List<String> serviceAreaIds;
  const MerchantRegistration({required this.ownerName,required this.phone,required this.email,
    required this.password,required this.storeName,required this.categoryId,required this.areaId,
    required this.address,required this.whatsapp,required this.description,required this.serviceAreaIds});
}

String encodeSession(AppUser user)=>jsonEncode(user.toJson());
AppUser decodeSession(String value)=>AppUser.fromJson(jsonDecode(value));
