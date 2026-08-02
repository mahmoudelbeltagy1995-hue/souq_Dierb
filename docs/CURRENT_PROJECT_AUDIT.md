# تدقيق مشروع TStore قبل التحويل إلى سوق ديرب

تاريخ التدقيق: 2026-08-02  
الفرع: `feature/souq-derb`  
المصدر: `https://github.com/mahmoodhamdi/TStore`

## الملخص التنفيذي

المستودع تطبيق Flutter حقيقي وليس قالب واجهات فقط. يحتوي على نحو 24 ألف سطر Dart، ويفصل معظم الميزات إلى Data وDomain وPresentation، ويستخدم Cubit وGetIt وSupabase. الأساس صالح للتطوير، لكنه متجر إلكتروني أحادي المتجر، ولا يحقق بعد عزل التجار أو التصفية حسب منطقة الخدمة أو إنشاء الطلب الموثوق من قاعدة البيانات.

أخطر مشكلة حالية هي أن `OrderRepositoryImpl.createOrder` يحسب الإجمالي من أسماء وأسعار يرسلها العميل ثم ينشئ `orders` و`order_items` في عمليتين منفصلتين. يستطيع عميل معدل تزوير السعر، وقد يُنشأ طلب ناقص إذا نجحت العملية الأولى وفشلت الثانية. يجب استبدال ذلك بـRPC ذرية تقرأ الأسعار والمخزون من قاعدة البيانات.

## البنية الحالية

- نقاط التشغيل: `lib/main_development.dart` و`lib/main_production.dart`.
- جذر الواجهة: `lib/t_store.dart`.
- الخدمات المشتركة: `lib/core`، وتشمل Supabase وDI والثيم والمكونات العامة.
- الميزات: auth، shop، cart، wishlist، orders، reviews، chat، notifications، personalization.
- تدفق البيانات المستهدف: Repository ثم Use Case ثم Cubit ثم View.
- توجد بقايا تنفيذ قديم موازٍ للتنفيذ الحديث في auth وshop وDI، منها مجلدا `repository` و`repositories` وملفا service locator، وهذا يزيد خطر استخدام طبقة خاطئة.

## الميزات الموجودة والقابلة للاستخدام بعد ضبط Supabase

- تسجيل الدخول وإنشاء الحساب وإعادة تعيين كلمة المرور عبر Supabase Auth.
- قراءة المنتجات والأقسام والعلامات والبانرات.
- السلة والمفضلة.
- إنشاء وعرض وإلغاء الطلبات بصيغتها القديمة، مع ملاحظة ضعف سلامة السعر والذرية.
- الملف الشخصي والعناوين.
- مراجعات المنتجات.
- رسائل الدعم والإشعارات الداخلية.
- رفع الملفات وخدمات Realtime عامة في `SupabaseService`.

هذه النتيجة مبنية على فحص الكود، وليست إثبات تشغيل؛ لم يتوفر Flutter SDK في بيئة التنفيذ عند التدقيق.

## الميزات الناقصة بالنسبة لسوق ديرب

- لا توجد كيانات stores أو store_service_areas أو service_areas.
- لا توجد أدوار merchant/admin/staff/driver موثوقة في قاعدة البيانات.
- المنتجات غير مرتبطة بمتجر.
- لا يوجد onboarding للتاجر أو دورة اعتماد متجر.
- لا توجد لوحة تاجر أو إدارة مخزون متعددة المتاجر.
- لا توجد اشتراكات تاجر.
- السلة لا تفرض متجرًا واحدًا على مستوى قاعدة البيانات.
- لا توجد خيارات منتجات منظمة.
- الطلب لا يُنشأ عبر Transaction/RPC آمنة.
- لا توجد قواعد انتقال حالة طلب موثوقة.
- مراجعات النظام الحالي تخص المنتج، لا متجرًا وطلبًا مسلمًا.
- الصفحة الرئيسية والبحث غير مفلترين حسب منطقة خدمة ومتجر معتمد.

## قاعدة البيانات الحالية

الملف `supabase_schema.sql` ينشئ: profiles، categories، brands، products، addresses، wishlist، cart_items، orders، order_items، reviews، banners، chat_messages، notifications، coupons.

العلاقات الأساسية الحالية:

- profile إلى auth.users بنسبة 1:1.
- product إلى category وbrand.
- cart/wishlist إلى user وproduct.
- order إلى user وaddress، وorder_items إلى order وproduct.
- review إلى user وproduct.

## مشاكل قاعدة البيانات وRLS

- الملف القديم يبدأ بأوامر DROP واسعة؛ غير مناسب لترقية إنتاجية آمنة.
- بعض سياسات `FOR ALL` لا تحتوي `WITH CHECK` صريحًا.
- المنتجات العامة لا تتحقق من اعتماد متجر أو اشتراكه لأنه لا يوجد متجر أصلًا.
- إنشاء الطلب من Flutter، والأسعار والإجمالي تحت سيطرة العميل.
- إنشاء order ثم items ليس Transaction واحدة.
- لا يوجد حجز مخزون أو سجل حركة مخزون.
- `handle_new_user` هو SECURITY DEFINER داخل public دون ضبط صريح لـsearch_path أو سحب EXECUTE من PUBLIC.
- دور المستخدم غير موجود في profile، ولا توجد صلاحيات تاجر أو أدمن.
- الجداول العامة لا تغطي حالات الحذف الناعم والتدقيق المطلوبة.

## Storage

يوفر الكود دوال رفع وحذف وعنوان عام، لكن لا توجد في المستودع migrations موثقة لإنشاء buckets وسياسات نوع/حجم/ملكية الصور. يلزم إنشاء buckets منفصلة للصور وسياسات Storage مقيدة.

## الاختبارات الحالية

يوجد widget test، واختبارات auth وcart وshop وorders وwishlist وreviews وchat وnotifications وpersonalization، إضافة إلى auth integration test. العدد جيد كبداية، لكن معظم الاختبارات تعتمد mocks ولا تغطي RLS أو RPC أو تعدد المتاجر.

الاختبارات المطلوبة لاحقًا: عزل متجر التاجر، متجر واحد في السلة، سلامة السعر، transitions، انتهاء الاشتراك، استرجاع المخزون، review بعد delivered، RTL، وحالات empty/error.

## Android والبيئة

- Application ID الحالي: `com.example.t_store`.
- compile/target SDK مضبوط على 36، Java/Kotlin 17.
- release يستخدم debug signing، وهو غير مقبول للنشر ويجب أن يصبح إعداد توقيع خارجي اختياريًا.
- flavorان development وproduction.
- `.env.example` يحتوي اسمي متغيري Supabase فقط ولا يحتوي أسرارًا.
- OAuth redirect ما زال `io.supabase.tstore`.
- لا توجد صلاحيات إنترنت ظاهرة في manifest الرئيسي، ويلزم التحقق من دمج manifests أثناء البناء.

## الحزم والمخاطر

- `pubspec.yaml` يتطلب Dart `^3.10.0`، ما يعني Flutter حديثًا؛ لا ينبغي تخفيضه أو تحديث كل الحزم بلا سبب.
- توجد ازدواجية في usecase/usecases وdependency_injection/depandancy_injection وطبقات auth/shop القديمة والحديثة.
- `geolocator` و`geocoding` و`permission_handler` موجودة رغم أن الخرائط اختيارية للمرحلة الأولى؛ يجب عدم طلب صلاحية الموقع تلقائيًا.
- اسم `.env` مدرج كـasset؛ يحتوي فقط publishable Supabase key في العميل، ويحظر service role منعًا تامًا.
- لا توجد GitHub Actions في النسخة المفحوصة.
- Flutter SDK غير مثبت في بيئة العمل الحالية، ولذلك تعذر تنفيذ `flutter pub get/analyze/test/build` في لحظة التدقيق.

## خطة التحويل

1. تثبيت الأساس والتحقق بواسطة Flutter SDK متوافق مع Dart 3.10.
2. تغيير الهوية وApplication ID وRTL والنصوص والتنسيقات المصرية.
3. إضافة migration تراكمية لمناطق الخدمة والأدوار والمتاجر والمنتجات والطلبات والاشتراكات والمراجعات والإشعارات.
4. إضافة RPC آمنة لإنشاء الطلب وحجز المخزون وRPC مضبوطة لتحديث الحالة.
5. إضافة features مستقلة: service_areas، stores، merchant_onboarding، merchant_dashboard، checkout.
6. تحويل repositories الحالية تدريجيًا مع adapters لتجنب كسر الميزات العاملة دفعة واحدة.
7. إضافة اختبارات domain/BLoC/widget واختبارات SQL/RLS محلية.
8. بناء APK debug ثم release/AAB بعد إضافة Flutter وAndroid SDK وبيئة Supabase.

## الملفات المتوقع تعديلها

- `pubspec.yaml` و`pubspec.lock` عند الحاجة فقط.
- `lib/t_store.dart` ونقاط التشغيل والثيم والنصوص والمنسقات.
- `lib/core/supabase/*` و`lib/core/dependency_injection/*`.
- features: auth، shop، cart، orders، personalization، reviews، notifications.
- features جديدة للمتاجر والمناطق ولوحة التاجر والإدارة.
- `android/app/build.gradle` وMainActivity وAndroid resources/manifests.
- `supabase/migrations/*` و`supabase/seed.sql`.
- README وملفات docs والاختبارات.

## القرارات التقنية

- إبقاء Clean Architecture وCubit/GetIt وعدم إعادة كتابة المشروع.
- استخدام migration تراكمية بدل تشغيل ملف DROP القديم على إنتاج.
- حفظ الدور في `profiles.role` والتحقق منه في قاعدة البيانات؛ عدم الوثوق بـuser_metadata أو الحالة المحلية.
- استخدام RPC PostgreSQL ذرية لإنشاء الطلب، مع idempotency key وحجز المخزون لحظة إنشاء الطلب، ثم إعادته عند الرفض/الإلغاء.
- إبقاء السلة في قاعدة البيانات، وفرض متجر واحد بقيود/trigger إلى جانب تحقق الواجهة.
- استخدام Snapshot لأسماء وأسعار المنتجات والخيارات في order items.
- السماح للمتجر بخدمة عدة مناطق عبر `store_service_areas`.
- الدفع في المرحلة الأولى `cash_on_delivery` فقط.
- FCM تكامل اختياري لاحقًا؛ الإشعارات داخل التطبيق لا تعتمد عليه.
- لا تُنشأ حسابات Auth ببذور SQL عامة؛ يوثق seed بيانات الكتالوج، وتُنشأ حسابات الاختبار عبر سكربت محلي/بيئة اختبار دون كلمات مرور إنتاجية.

## المخاطر المتوقعة

- عدم توافق موديلات Flutter القديمة مع أسماء الأعمدة الجديدة؛ ستستخدم migration توافقية وتحديثًا تدريجيًا.
- تعقيد RLS مع وظائف SECURITY DEFINER؛ يلزم search_path ثابت، تحقق auth داخل الوظيفة، سحب التنفيذ من PUBLIC ومنح أقل صلاحية لازمة.
- سباق المخزون والطلبات المتكررة؛ يحل بقفل الصفوف وTransaction وidempotency key.
- غياب مشروع Supabase وFirebase الفعليين يمنع اختبار التكامل الخارجي، لكنه لا يمنع إكمال migrations والكود والاختبارات المعزولة.

## سجل التنفيذ

- 2026-08-02: استيراد المستودع وإنشاء `feature/souq-derb`.
- 2026-08-02: فحص البنية والاعتماديات وSupabase والاختبارات وAndroid.
- 2026-08-02: اكتشاف غياب Flutter SDK من بيئة التنفيذ وتسجيله كعائق تحقق، لا كعائق لتطوير الملفات.
