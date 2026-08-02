# سوق ديرب — Souq Derb

تطبيق Flutter محلي متعدد المتاجر لخدمة ديرب نجم والقرى التابعة. بُني تطويرًا على TStore مع الحفاظ على Clean Architecture وCubit وSupabase.

## المتطلبات

- Flutter متوافق مع Dart `^3.10.0`
- Java 17 وAndroid SDK 36
- مشروع Supabase

## الإعداد

1. مرّر `SUPABASE_URL` و`SUPABASE_ANON_KEY` العامة فقط باستخدام `--dart-define`؛ لا تُحفظ الأسرار في ملفات أو Git.
2. طبّق ملفات `supabase/migrations` بالترتيب عبر Supabase CLI حديث.
3. شغّل `supabase/seed.sql` في بيئة التطوير لإضافة المناطق وأقسام المتاجر.
4. أنشئ حسابات الاختبار كما في `docs/TEST_ACCOUNTS.md`.

```bash
flutter pub get
flutter run --flavor development -t lib/main_development.dart \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=PUBLIC_ANON_KEY
flutter analyze
flutter test
```

للتجربة المحلية فورًا دون بيانات وهمية داخل نسخة الإنتاج:

```bash
flutter run --flavor development -t lib/main_demo.dart
```

حسابات Demo: `customer@souqderb.demo` و`merchant@souqderb.demo` و`pending@souqderb.demo` و`admin@souqderb.demo`، وكلمة المرور `123456`.

تعليمات APK/AAB في `docs/ANDROID_BUILD.md`.

## البنية

- `lib/core`: Supabase وDI والثيم والخدمات المشتركة.
- `lib/features`: الميزات بطبقات data/domain/presentation.
- `supabase/migrations`: مخطط وترقيات تراكمية وRLS وRPC.
- `test`: unit وBLoC وwidget/integration tests.
- `docs`: التدقيق والمعمارية والمخطط والأمان والبناء والتقدم.

## الأدوار

customer وmerchant وadmin منفذة في قاعدة البيانات. staff وdriver مجهزان للتوسع دون تطبيق مندوب في المرحلة الحالية.

## الأمان

لا تضف service role أو مفاتيح توقيع إلى Flutter/Git. إنشاء الطلب يجب أن يمر عبر `create_souq_order`؛ الأسعار التي يعرضها الهاتف ليست مصدر الحقيقة.

## القيود الحالية والمرحلة التالية

FCM غير مفعّل، ورفع الصور يحتاج إعداد Storage الخارجي. التالي هو تطبيق migrations على مشروع Supabase المخصص لسوق ديرب، تشغيل Security/Performance Advisors، ثم إخراج APK/AAB من بيئة تسمح لـGradle Plugin Portal. راجع `docs/PHASE_1_COMPLETION_REPORT.md` للحالة الدقيقة.
