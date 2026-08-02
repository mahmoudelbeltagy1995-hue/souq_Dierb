# RLS Policies

- الجداول الجديدة كلها مفعّل عليها RLS.
- anon/authenticated يقرآن المناطق والأقسام النشطة والمتاجر المعتمدة النشطة ذات الاشتراك الساري فقط.
- العنوان ملك لصاحبه باستخدام `auth.uid()` في USING وWITH CHECK.
- التاجر يرى متجره، وينشئ متجرًا pending، ويعدل بياناته قبل الاعتماد. الإدارة وحدها تغير الاعتماد والاشتراك.
- منتجات التاجر مرتبطة بمتجره عبر `private.owns_store`، ولا تظهر للعامة إلا عندما يكون المنتج والمتجر صالحين.
- role يُقرأ من profiles بواسطة helper في schema غير مكشوف، وليس من user metadata.
- وظائف checkout/transition تسحب EXECUTE من PUBLIC وanon وتمنحه للمستخدم authenticated فقط، ثم تتحقق داخليًا من auth والملكية.
- لا مكان لـservice role key داخل Flutter.

قبل الإنتاج شغّل Supabase Database Advisors واختبارات RLS بحسابات منفصلة لكل دور.
