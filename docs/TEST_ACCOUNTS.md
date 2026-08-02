# حسابات الاختبار

لا يحتوي المستودع على كلمات مرور أو حسابات Auth جاهزة. أنشئ الحسابات التالية في مشروع Supabase المحلي أو المخصص للاختبار، ثم اضبط `profiles.role` من جلسة إدارية آمنة:

| الغرض | البريد المقترح | الدور | الحالة |
|---|---|---|---|
| أدمن | `admin@souqderb.test` | admin | active |
| عميل | `customer@souqderb.test` | customer | active |
| تاجر معتمد | `merchant.approved@souqderb.test` | merchant | active |
| تاجر قيد المراجعة | `merchant.pending@souqderb.test` | merchant | pending |

اختر كلمات مرور محلية مؤقتة من خارج Git، ولا تستخدم هذه النطاقات في الإنتاج. بيانات المناطق والأقسام فقط موجودة في `supabase/seed.sql` لأنها لا تتضمن بيانات شخصية أو أسرارًا.
