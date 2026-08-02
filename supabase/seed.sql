-- Idempotent catalogue seed for local/test environments only.
-- Auth test users must be created through Supabase Auth tooling; never put passwords in SQL.
insert into public.service_areas(name_ar,name_en,delivery_fee,minimum_order,estimated_delivery_minutes,sort_order) values
('ديرب نجم','Diarb Negm',20,50,35,1),('الصانية','El Saneya',25,60,45,2),('صافور','Saft Zurayq',30,75,50,3),
('جميزة بني عمرو','Gemeiza Bani Amr',30,75,50,4),('دبيج','Dabig',30,75,50,5),('المناصافور','El Manasafour',25,60,45,6),
('قرموط صهبرة','Qarmout Sahbara',30,75,50,7),('العصايد','El Asayed',30,75,50,8),('فرغان','Farghan',30,75,50,9),
('منشأة صهبرة','Manshaat Sahbara',30,75,50,10)
on conflict(name_ar) do update set name_en=excluded.name_en, sort_order=excluded.sort_order;

insert into public.store_categories(name_ar,name_en,sort_order) values
('مطاعم','Restaurants',1),('سوبر ماركت','Supermarkets',2),('خضروات وفاكهة','Fruit and Vegetables',3),
('حلويات ومخبوزات','Sweets and Bakeries',4),('ملابس','Clothing',5),('أحذية وشنط','Shoes and Bags',6),
('موبايلات وإلكترونيات','Mobiles and Electronics',7),('أدوات منزلية','Homeware',8),('مستحضرات تجميل','Cosmetics',9),
('مكتبات','Stationery',10),('خدمات منزلية','Home Services',11),('قطع غيار','Spare Parts',12),('محلات أخرى','Other Stores',13)
on conflict(name_ar) do update set name_en=excluded.name_en, sort_order=excluded.sort_order;
