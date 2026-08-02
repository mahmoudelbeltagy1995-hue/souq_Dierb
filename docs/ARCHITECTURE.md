# Architecture

سوق ديرب يحافظ على Clean Architecture الموجودة: `data` للموديلات وتنفيذ المستودعات، `domain` للكيانات والعقود وقواعد العمل، و`presentation` للـCubit والواجهات. `GetIt` يربط الاعتماديات في `lib/core/dependency_injection/service_locator.dart`، وSupabase هو مصدر الحقيقة.

القرارات الحاكمة:

- Flutter لا يقرر الصلاحية ولا الإجمالي النهائي.
- العميل يستدعي `create_souq_order` فقط؛ الوظيفة تقفل صفوف المخزون وتحسب السعر وتنشئ الطلب ذريًا.
- صلاحيات العميل والتاجر والأدمن تتكرر كدفاع متعدد الطبقات: RLS، repository/use case، ثم الواجهة.
- المزايا الجديدة موجودة في `features/marketplace` و`features/checkout`، ويجري ترحيل المزايا القديمة تدريجيًا لتجنب إعادة كتابة واسعة.
- المندوب وstaff موجودان في نموذج الدور للتوسع، دون واجهات في المرحلة الأولى.

## تدفق الطلب

1. الواجهة تجمع product IDs والكميات وoption IDs فقط.
2. SecureCheckoutRepository يستدعي RPC مع UUID idempotency.
3. PostgreSQL يتحقق من المستخدم والعنوان والمنطقة والمتجر والاشتراك والمنتجات والخيارات والمخزون.
4. تُحفظ snapshots ويُحجز المخزون وتُسجل inventory movements داخل المعاملة نفسها.
5. انتقال الحالة يتم عبر `transition_souq_order` وفق تسلسل ثابت، وتعيد الوظيفة المخزون عند الرفض أو الإلغاء.
