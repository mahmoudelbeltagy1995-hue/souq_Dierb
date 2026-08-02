# Database Schema

المصدر التنفيذي للمخطط هو ملفات `supabase/migrations` بالترتيب، وليس ملف `supabase_schema.sql` القديم الذي يبقى مرجعًا للنسخة الأصلية.

المجموعات الرئيسية:

- الهوية: auth.users ← profiles (role, account_status, service_area).
- الجغرافيا: service_areas ← customer_addresses وstore_service_areas.
- المتاجر: store_categories ← stores ← store_product_categories.
- الكتالوج: products ← product_option_groups ← product_options.
- التجارة: cart_items، orders، order_items، order_item_options.
- التشغيل: merchant_subscriptions وinventory_movements وnotifications.
- الثقة: store_reviews، وتقييم واحد لكل order مسلم.

تستخدم المعرفات UUID، باستثناء `orders.order_number` وهو رقم عرض متزايد. الأسعار numeric(12,2)، والتواريخ timestamptz، والقيود تمنع القيم السالبة والحالات غير المعروفة.
