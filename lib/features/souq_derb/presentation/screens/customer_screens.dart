import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models.dart';
import '../cubit/souq_derb_cubit.dart';
import '../cubit/souq_derb_state.dart';
import '../widgets/common.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    const pages = [CustomerHomeScreen(), StoresScreen(), CartScreen(), CustomerOrdersScreen(), AccountScreen()];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'المحلات'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'السلة'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'طلباتي'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) {
    final area = state.areas.where((a) => a.id == state.selectedAreaId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('سوق ديرب'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined))]),
      body: RefreshIndicator(
        onRefresh: context.read<SouqDerbCubit>().refreshCustomer,
        child: ListView(padding: const EdgeInsets.all(14), children: [
          ListTile(leading: const Icon(Icons.location_on, color: souqGreen), title: Text(area?.nameAr ?? 'اختر منطقتك'), onTap: () => _chooseArea(context, state)),
          SearchBar(hintText: 'ابحث عن محل أو منتج', leading: const Icon(Icons.search), onSubmitted: (q) => Navigator.push(context, MaterialPageRoute(builder: (_) => StoresScreen(query: q)))),
          const SizedBox(height: 14),
          Container(height: 125, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: souqGreen, borderRadius: BorderRadius.circular(20)), child: const Row(children: [Expanded(child: Text('اطلب من محلات بلدك\nتوصيل سريع وأسعار واضحة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))), Icon(Icons.shopping_bag, color: souqGold, size: 62)])),
          const SectionTitle('أقسام المحلات'),
          Wrap(spacing: 8, children: state.categories.map((c) => ActionChip(label: Text('${c.icon} ${c.name}'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoresScreen(categoryId: c.id))))).toList()),
          const SectionTitle('محلات متاحة'),
          if (state.stores.isEmpty) const SizedBox(height: 240, child: EmptyView(icon: Icons.store_mall_directory_outlined, title: 'لا توجد محلات حاليًا', subtitle: 'غيّر المنطقة أو حاول لاحقًا'))
          else ...state.stores.map((store) => StoreCard(store: store, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailsScreen(store: store))))),
        ]),
      ),
    );
  });
}

void _chooseArea(BuildContext context, SouqDerbState state) => showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: ListView(shrinkWrap: true, children: state.areas.map((a) => ListTile(title: Text(a.nameAr), subtitle: Text('${a.deliveryFee.toStringAsFixed(0)} ج.م'), onTap: () { Navigator.pop(context); context.read<SouqDerbCubit>().changeArea(a.id); })).toList())));

class StoresScreen extends StatelessWidget {
  final String? categoryId;
  final String? query;
  const StoresScreen({super.key, this.categoryId, this.query});
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('المحلات')),
    body: ListView(padding: const EdgeInsets.all(12), children: [
      SearchBar(hintText: query ?? 'ابحث', leading: const Icon(Icons.search), onSubmitted: (q) => context.read<SouqDerbCubit>().refreshCustomer(categoryId: categoryId, query: q)),
      const SizedBox(height: 12),
      ...state.stores.map((s) => StoreCard(store: s, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailsScreen(store: s))))),
    ]),
  ));
}

class StoreDetailsScreen extends StatelessWidget {
  final StoreData store;
  const StoreDetailsScreen({super.key, required this.store});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(store.name)),
    body: FutureBuilder<List<ProductData>>(
      future: context.read<SouqDerbCubit>().products(store.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingView();
        return ListView(padding: const EdgeInsets.all(14), children: [
          Container(height: 140, decoration: BoxDecoration(color: souqGreen, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.storefront, color: Colors.white, size: 72)),
          ListTile(title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21)), subtitle: Text('⭐ ${store.rating} • ${store.deliveryMinutes} دقيقة')),
          Text(store.description),
          if (!store.isOpen) const Card(color: Color(0xFFFFF3E0), child: ListTile(title: Text('المتجر مغلق حاليًا'), subtitle: Text('يمكنك التصفح فقط'))),
          const SectionTitle('المنتجات'),
          ...snapshot.data!.map((p) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.shopping_bag)), title: Text(p.name), subtitle: PriceText(p.price), trailing: FilledButton(onPressed: store.isOpen && p.inStock ? () => _add(context, p) : null, child: const Text('أضف'))))),
        ]);
      },
    ),
  );
}

Future<void> _add(BuildContext context, ProductData product) async {
  final line = CartLine(product: product, quantity: 1, options: const [], note: '');
  var ok = await context.read<SouqDerbCubit>().addToCart(line);
  if (!ok && context.mounted) {
    final replace = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('متجر مختلف'), content: const Text('تحتوي سلتك على منتجات من متجر آخر. هل تريد مسح السلة؟'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('مسح'))]));
    if (replace == true && context.mounted) ok = await context.read<SouqDerbCubit>().addToCart(line, replace: true);
  }
  if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة للسلة')));
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) {
    if (state.cart.isEmpty) return Scaffold(appBar: AppBar(title: const Text('السلة')), body: const EmptyView(icon: Icons.shopping_cart_outlined, title: 'سلتك فارغة', subtitle: 'أضف منتجات لبدء الطلب'));
    final store = state.stores.where((s) => s.id == state.cartStoreId).firstOrNull;
    return Scaffold(appBar: AppBar(title: const Text('السلة')), body: ListView(padding: const EdgeInsets.all(14), children: [
      ...state.cart.asMap().entries.map((e) => Card(child: ListTile(title: Text(e.value.product.name), subtitle: PriceText(e.value.total), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => context.read<SouqDerbCubit>().updateQuantity(e.key, 0))))),
      ListTile(title: const Text('الإجمالي'), trailing: PriceText(state.cartSubtotal + (store?.deliveryFee ?? 0))),
      FilledButton(onPressed: store == null ? null : () => _checkout(context, store), child: const Text('تأكيد الطلب • الدفع عند الاستلام')),
    ]));
  });
}

Future<void> _checkout(BuildContext context, StoreData store) async {
  final addresses = await context.read<SouqDerbCubit>().addresses();
  if (!context.mounted) return;
  if (addresses.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف عنوانًا من الحساب أولًا'))); return; }
  try {
    final order = await context.read<SouqDerbCubit>().checkout(address: addresses.first, note: '');
    if (context.mounted && order != null) showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('تم إرسال طلبك'), content: Text('رقم الطلب: ${order.number}\nالإجمالي: ${order.total.toStringAsFixed(0)} ج.م'), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))]));
  } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
}

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) => Scaffold(appBar: AppBar(title: const Text('طلباتي')), body: state.orders.isEmpty ? const EmptyView(icon: Icons.receipt_long_outlined, title: 'لا توجد طلبات', subtitle: 'طلباتك ستظهر هنا') : ListView(children: state.orders.map((o) => Card(child: ListTile(title: Text('طلب ${o.number}'), subtitle: Text(orderStatusText(o.status)), trailing: PriceText(o.total)))).toList())));
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override Widget build(BuildContext context) {
    final state = context.watch<SouqDerbCubit>().state;
    return Scaffold(appBar: AppBar(title: const Text('حسابي')), body: ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(state.user?.fullName ?? ''), subtitle: Text(state.user?.phone ?? '')),
      ListTile(leading: const Icon(Icons.location_on), title: const Text('عناوين التوصيل'), onTap: () => _quickAddress(context, state)),
      OutlinedButton.icon(onPressed: () => context.read<SouqDerbCubit>().signOut(), icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
    ]));
  }
}

Future<void> _quickAddress(BuildContext context, SouqDerbState state) async {
  if (state.selectedAreaId == null || state.user == null) return;
  await context.read<SouqDerbCubit>().addAddress(CustomerAddress(id: 'address-${DateTime.now().microsecondsSinceEpoch}', title: 'المنزل', name: state.user!.fullName, phone: state.user!.phone, areaId: state.selectedAreaId!, street: 'العنوان الرئيسي', isDefault: true));
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ عنوان تجريبي للجلسة')));
}
