import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import '../domain/souq_derb_repository.dart';

class DemoSouqDerbRepository implements SouqDerbRepository {
  static const _sessionKey='souq_derb_demo_session',_cartKey='souq_derb_demo_cart';
  late SharedPreferences _prefs; AppUser? _session;
  final List<AppUser> _users=[
    const AppUser(id:'u-customer',fullName:'عميل سوق ديرب',phone:'01012345678',email:'customer@souqderb.demo',role:AppRole.customer,serviceAreaId:'area-derb'),
    const AppUser(id:'u-merchant',fullName:'أحمد صاحب المتجر',phone:'01112345678',email:'merchant@souqderb.demo',role:AppRole.merchant,serviceAreaId:'area-derb'),
    const AppUser(id:'u-pending',fullName:'تاجر قيد المراجعة',phone:'01212345678',email:'pending@souqderb.demo',role:AppRole.merchant,status:AccountStatus.pending,serviceAreaId:'area-derb'),
    const AppUser(id:'u-admin',fullName:'إدارة سوق ديرب',phone:'01512345678',email:'admin@souqderb.demo',role:AppRole.admin),
  ];
  final _passwords=<String,String>{'customer@souqderb.demo':'123456','merchant@souqderb.demo':'123456',
    'pending@souqderb.demo':'123456','admin@souqderb.demo':'123456'};
  final List<ServiceArea> _areas=const [
    ServiceArea('area-derb','ديرب نجم',20,50,35),ServiceArea('area-saneya','الصانية',25,60,45),
    ServiceArea('area-safour','صافور',30,75,50),ServiceArea('area-gemeiza','جميزة بني عمرو',30,75,50),
    ServiceArea('area-dabig','دبيج',30,75,50),ServiceArea('area-manasafour','المناصافور',25,60,45),
  ];
  final List<StoreCategory> _categories=const [
    StoreCategory('cat-restaurants','مطاعم','🍔'),StoreCategory('cat-market','سوبر ماركت','🛒'),
    StoreCategory('cat-veg','خضروات وفاكهة','🥬'),StoreCategory('cat-sweets','حلويات ومخبوزات','🧁'),
    StoreCategory('cat-clothes','ملابس','👕'),StoreCategory('cat-mobile','موبايلات وإلكترونيات','📱'),
    StoreCategory('cat-home','أدوات منزلية','🏠'),StoreCategory('cat-other','محلات أخرى','🏪'),
  ];
  late List<StoreData> _stores; late List<ProductData> _products; final List<CustomerAddress> _addresses=[];
  final List<OrderData> _orders=[]; final Map<String,OrderData> _idempotent={};
  @override bool get isDemo=>true;

  @override Future<void> initialize() async {
    _prefs=await SharedPreferences.getInstance();
    final saved=_prefs.getString(_sessionKey); if(saved!=null) _session=decodeSession(saved);
    _stores=[
      const StoreData(id:'store-burger',ownerId:'u-merchant',categoryId:'cat-restaurants',name:'برجر البلد',
        description:'برجر طازج ووجبات سريعة من قلب ديرب نجم',phone:'01012345678',whatsapp:'01012345678',
        address:'شارع النصر، ديرب نجم',areaId:'area-derb',serviceAreaIds:['area-derb','area-saneya'],
        deliveryFee:20,minimumOrder:60,deliveryMinutes:35,rating:4.8,ratingsCount:126,
        approval:StoreApproval.approved,subscription:SubscriptionStatus.trial),
      const StoreData(id:'store-market',ownerId:'u-market',categoryId:'cat-market',name:'ماركت الخير',
        description:'كل احتياجات البيت بأسعار يومية',phone:'01123456789',whatsapp:'01123456789',
        address:'ميدان المحطة، ديرب نجم',areaId:'area-derb',serviceAreaIds:['area-derb','area-saneya','area-safour'],
        deliveryFee:18,minimumOrder:100,deliveryMinutes:40,rating:4.6,ratingsCount:89,
        approval:StoreApproval.approved,subscription:SubscriptionStatus.active),
      const StoreData(id:'store-sweets',ownerId:'u-sweets',categoryId:'cat-sweets',name:'حلواني السعادة',
        description:'حلويات شرقية ومخبوزات يومية',phone:'01234567890',address:'شارع المركز، ديرب نجم',
        areaId:'area-derb',serviceAreaIds:['area-derb'],deliveryFee:15,minimumOrder:50,deliveryMinutes:30,
        rating:4.9,ratingsCount:211,approval:StoreApproval.approved,subscription:SubscriptionStatus.active),
      const StoreData(id:'store-pending',ownerId:'u-pending',categoryId:'cat-mobile',name:'موبايل تك',
        description:'هواتف وإكسسوارات',phone:'01212345678',address:'ديرب نجم',areaId:'area-derb',
        serviceAreaIds:['area-derb'],approval:StoreApproval.pending),
    ];
    const size=ProductOptionGroup('g-size','الحجم',[ProductOption('small','صغير'),ProductOption('medium','وسط',extra:15),ProductOption('large','كبير',extra:30)],required:true);
    const extras=ProductOptionGroup('g-extra','إضافات',[ProductOption('cheese','جبنة إضافية',extra:12),ProductOption('sauce','صوص',extra:7)],multiple:true);
    _products=[
      const ProductData(id:'p-burger-1',storeId:'store-burger',categoryId:'meals',name:'برجر لحم بلدي',description:'قطعة لحم بلدي مع الخضار والصوص',price:95,compareAtPrice:110,stock:25,featured:true,optionGroups:[size,extras]),
      const ProductData(id:'p-burger-2',storeId:'store-burger',categoryId:'meals',name:'وجبة تشيكن',description:'ساندوتش تشيكن مع بطاطس ومشروب',price:120,stock:14,optionGroups:[size,extras]),
      const ProductData(id:'p-market-1',storeId:'store-market',categoryId:'groceries',name:'أرز مصري 1 كجم',description:'أرز مصري فاخر',price:42,stock:60,featured:true,unit:'كيس'),
      const ProductData(id:'p-market-2',storeId:'store-market',categoryId:'groceries',name:'زيت خليط 1 لتر',description:'زيت طعام',price:78,compareAtPrice:85,stock:35,unit:'زجاجة'),
      const ProductData(id:'p-sweets-1',storeId:'store-sweets',categoryId:'oriental',name:'كنافة سادة',description:'كنافة طازجة بالسمن البلدي',price:140,stock:18,featured:true,unit:'كيلو'),
      const ProductData(id:'p-sweets-2',storeId:'store-sweets',categoryId:'bakery',name:'فطير مشلتت',description:'فطير طازج حسب الطلب',price:130,stock:0,available:false,unit:'قطعة'),
    ];
    _orders.addAll([
      OrderData(id:'o-1',number:'SD-1001',customerId:'u-customer',storeId:'store-burger',address:'المنزل - شارع النصر',
        items:[const OrderLine('برجر لحم بلدي',2,95,[])],status:OrderStatus.preparing,subtotal:190,deliveryFee:20,total:210,createdAt:DateTime.now().subtract(const Duration(hours:1))),
      OrderData(id:'o-2',number:'SD-0998',customerId:'u-customer',storeId:'store-market',address:'المنزل - شارع النصر',
        items:[const OrderLine('أرز مصري 1 كجم',2,42,[])],status:OrderStatus.delivered,subtotal:84,deliveryFee:18,total:102,createdAt:DateTime.now().subtract(const Duration(days:2))),
    ]);
    _addresses.add(const CustomerAddress(id:'addr-1',title:'المنزل',name:'عميل سوق ديرب',phone:'01012345678',areaId:'area-derb',street:'شارع النصر، بجوار المدرسة',landmark:'أمام الصيدلية',isDefault:true));
  }
  Future<T> _delay<T>(T value) async { await Future<void>.delayed(const Duration(milliseconds:250)); return value; }
  void _requireUser(){if(_session==null) throw const RepositoryException('انتهت الجلسة. سجل الدخول مرة أخرى.');}
  @override Future<AppUser?> currentUser() async=>_delay(_session);
  @override Future<AppUser> signIn(String email,String password) async {
    final normalized=email.trim().toLowerCase();
    if(_passwords[normalized]!=password) throw const RepositoryException('البريد الإلكتروني أو كلمة المرور غير صحيحة');
    _session=_users.firstWhere((u)=>u.email==normalized); await _prefs.setString(_sessionKey,encodeSession(_session!)); return _delay(_session!);
  }
  @override Future<AppUser> registerCustomer({required String name,required String phone,required String email,
      required String password,required String serviceAreaId}) async {
    if(_users.any((u)=>u.email==email.toLowerCase())) throw const RepositoryException('البريد الإلكتروني مسجل بالفعل');
    final user=AppUser(id:'u-${DateTime.now().millisecondsSinceEpoch}',fullName:name,phone:phone,email:email.toLowerCase(),role:AppRole.customer,serviceAreaId:serviceAreaId);
    _users.add(user);_passwords[user.email]=password;_session=user;await _prefs.setString(_sessionKey,encodeSession(user));return _delay(user);
  }
  @override Future<AppUser> registerMerchant(MerchantRegistration r) async {
    final user=AppUser(id:'u-${DateTime.now().millisecondsSinceEpoch}',fullName:r.ownerName,phone:r.phone,email:r.email.toLowerCase(),role:AppRole.merchant,status:AccountStatus.pending,serviceAreaId:r.areaId);
    _users.add(user);_passwords[user.email]=r.password;_stores.add(StoreData(id:'store-${DateTime.now().millisecondsSinceEpoch}',ownerId:user.id,categoryId:r.categoryId,name:r.storeName,description:r.description,phone:r.phone,whatsapp:r.whatsapp,address:r.address,areaId:r.areaId,serviceAreaIds:r.serviceAreaIds));
    _session=user;await _prefs.setString(_sessionKey,encodeSession(user));return _delay(user);
  }
  @override Future<void> resetPassword(String email)=>_delay(null);
  @override Future<void> signOut() async{_session=null;await _prefs.remove(_sessionKey);}
  @override Future<List<ServiceArea>> areas()=>_delay(List.unmodifiable(_areas));
  @override Future<List<StoreCategory>> storeCategories()=>_delay(List.unmodifiable(_categories));
  @override Future<List<StoreData>> stores({required String areaId,String? categoryId,String query='',bool openOnly=false})=>_delay(_stores.where((s)=>s.visible&&s.serviceAreaIds.contains(areaId)&&(categoryId==null||s.categoryId==categoryId)&&(!openOnly||s.isOpen)&&s.name.contains(query.trim())).toList());
  @override Future<StoreData?> store(String id)=>_delay(_stores.where((s)=>s.id==id).firstOrNull);
  @override Future<List<ProductData>> products(String storeId,{String query=''})=>_delay(_products.where((p)=>p.storeId==storeId&&p.name.contains(query.trim())).toList());
  @override Future<List<CustomerAddress>> addresses() async{_requireUser();return _delay(List.unmodifiable(_addresses));}
  @override Future<CustomerAddress> addAddress(CustomerAddress address) async{_requireUser();_addresses.add(address);return _delay(address);}
  @override Future<List<CartLine>> cart() async {
    final raw=_prefs.getString(_cartKey);if(raw==null)return [];
    final list=jsonDecode(raw) as List;final result=<CartLine>[];
    for(final row in list.cast<Map<String,dynamic>>()){
      final product=_products.where((p)=>p.id==row['productId']).firstOrNull;if(product==null)continue;
      final ids=(row['optionIds'] as List? ?? []).cast<String>();final options=product.optionGroups.expand((g)=>g.options).where((o)=>ids.contains(o.id)).toList();
      result.add(CartLine(product:product,quantity:row['quantity'] as int,options:options,note:row['note'] as String? ?? ''));
    }return result;
  }
  @override Future<void> saveCart(List<CartLine> lines)=>_prefs.setString(_cartKey,jsonEncode(lines.map((e)=>e.toJson()).toList()));
  @override Future<OrderData> checkout({required String storeId,required CustomerAddress address,required List<CartLine> lines,required String idempotencyKey,String? note}) async {
    _requireUser();if(_idempotent.containsKey(idempotencyKey))return _idempotent[idempotencyKey]!;
    final s=_stores.firstWhere((e)=>e.id==storeId);if(!s.visible||!s.isOpen)throw const RepositoryException('المتجر مغلق أو غير متاح حاليًا');
    if(!s.serviceAreaIds.contains(address.areaId))throw const RepositoryException('المتجر لا يخدم هذا العنوان');
    if(lines.any((l)=>l.product.storeId!=storeId))throw const RepositoryException('يجب أن تكون جميع المنتجات من متجر واحد');
    if(lines.any((l)=>!l.product.inStock||l.quantity>l.product.stock))throw const RepositoryException('أحد المنتجات نفد أو الكمية غير متوفرة');
    final subtotal=lines.fold<double>(0,(sum,l)=>sum+l.total);if(subtotal<s.minimumOrder)throw RepositoryException('الحد الأدنى للطلب ${s.minimumOrder.toStringAsFixed(0)} ج.م');
    final order=OrderData(id:'o-${DateTime.now().microsecondsSinceEpoch}',number:'SD-${1000+_orders.length}',customerId:_session!.id,storeId:storeId,address:'${address.title} - ${address.street}',items:lines.map((l)=>OrderLine(l.product.name,l.quantity,l.product.price,l.options)).toList(),status:OrderStatus.pending,subtotal:subtotal,deliveryFee:s.deliveryFee,total:subtotal+s.deliveryFee,createdAt:DateTime.now(),note:note);
    _orders.insert(0,order);_idempotent[idempotencyKey]=order;return _delay(order);
  }
  @override Future<List<OrderData>> customerOrders() async{_requireUser();return _delay(_orders.where((o)=>o.customerId==_session!.id).toList());}
  @override Future<List<OrderData>> merchantOrders(String storeId)=>_delay(_orders.where((o)=>o.storeId==storeId).toList());
  @override Future<OrderData> transitionOrder(String orderId,OrderStatus status,{String? reason}) async {
    final i=_orders.indexWhere((o)=>o.id==orderId);if(i<0)throw const RepositoryException('الطلب غير موجود');
    final from=_orders[i].status;final allowed=<OrderStatus,List<OrderStatus>>{OrderStatus.pending:[OrderStatus.accepted,OrderStatus.rejected,OrderStatus.cancelled],OrderStatus.accepted:[OrderStatus.preparing],OrderStatus.preparing:[OrderStatus.ready],OrderStatus.ready:[OrderStatus.outForDelivery],OrderStatus.outForDelivery:[OrderStatus.delivered]};
    if(!(allowed[from]?.contains(status)??false))throw const RepositoryException('انتقال حالة الطلب غير مسموح');
    if((status==OrderStatus.rejected||status==OrderStatus.cancelled)&&(reason?.trim().isEmpty??true))throw const RepositoryException('يجب إدخال السبب');
    _orders[i]=_orders[i].copyWith(status:status,reason:reason);return _delay(_orders[i]);
  }
  @override Future<StoreData?> merchantStore() async{_requireUser();return _delay(_stores.where((s)=>s.ownerId==_session!.id).firstOrNull);}
  @override Future<StoreData> updateStore(StoreData store) async{final i=_stores.indexWhere((s)=>s.id==store.id);if(i<0)throw const RepositoryException('المتجر غير موجود');_stores[i]=store;return _delay(store);}
  @override Future<List<ProductData>> merchantProducts(String storeId)=>products(storeId);
  @override Future<ProductData> saveProduct(ProductData product) async{final i=_products.indexWhere((p)=>p.id==product.id);if(i<0){_products.add(product);}else{_products[i]=product;}return _delay(product);}
  @override Future<void> deleteProduct(String productId) async{_products.removeWhere((p)=>p.id==productId);await _delay(null);}
  @override Future<List<StoreData>> storeApplications()=>_delay(_stores.where((s)=>s.approval!=StoreApproval.approved).toList());
  @override Future<StoreData> reviewStore(String storeId,StoreApproval status,{String? reason}) async{final i=_stores.indexWhere((s)=>s.id==storeId);if(i<0)throw const RepositoryException('المتجر غير موجود');_stores[i]=_stores[i].copyWith(approval:status,rejectionReason:reason);return _delay(_stores[i]);}
  @override Future<StoreData> setSubscription(String storeId,SubscriptionStatus status) async{final i=_stores.indexWhere((s)=>s.id==storeId);_stores[i]=_stores[i].copyWith(subscription:status);return _delay(_stores[i]);}
}
