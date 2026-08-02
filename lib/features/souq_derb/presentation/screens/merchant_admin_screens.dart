import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models.dart';
import '../cubit/souq_derb_cubit.dart';
import '../cubit/souq_derb_state.dart';
import '../widgets/common.dart';

class MerchantGate extends StatelessWidget {
  const MerchantGate({super.key});
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) {
    final store = state.merchantStore;
    if (store == null) return const LoadingView();
    if (store.approval != StoreApproval.approved) return Scaffold(appBar: AppBar(actions: [IconButton(onPressed: () => context.read<SouqDerbCubit>().signOut(), icon: const Icon(Icons.logout))]), body: EmptyView(icon: store.approval == StoreApproval.rejected ? Icons.edit_note : Icons.hourglass_top, title: store.approval == StoreApproval.rejected ? 'تم رفض طلب المتجر' : 'طلب إنشاء متجرك قيد المراجعة', subtitle: store.rejectionReason ?? 'سنبلغك فور مراجعة الطلب'));
    return const MerchantShell();
  });
}

class MerchantShell extends StatefulWidget { const MerchantShell({super.key}); @override State<MerchantShell> createState() => _MerchantShellState(); }
class _MerchantShellState extends State<MerchantShell> {
  int index = 0;
  @override Widget build(BuildContext context) {
    const pages = [MerchantDashboard(), MerchantOrders(), MerchantProducts(), MerchantStore(), MerchantAccount()];
    return Scaffold(body: IndexedStack(index: index, children: pages), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.receipt_long), label: 'الطلبات'), NavigationDestination(icon: Icon(Icons.inventory), label: 'المنتجات'), NavigationDestination(icon: Icon(Icons.store), label: 'المتجر'), NavigationDestination(icon: Icon(Icons.person), label: 'الحساب')]));
  }
}

class MerchantDashboard extends StatelessWidget { const MerchantDashboard({super.key}); @override Widget build(BuildContext context) { final state = context.watch<SouqDerbCubit>().state; return Scaffold(appBar: AppBar(title: const Text('لوحة التاجر')), body: ListView(padding: const EdgeInsets.all(14), children: [Card(child: ListTile(title: const Text('طلبات جديدة'), trailing: Text('${state.orders.where((o) => o.status == OrderStatus.pending).length}', style: const TextStyle(fontSize: 24)))), Card(child: ListTile(title: const Text('منتجات منخفضة المخزون'), trailing: const Icon(Icons.warning_amber))), SwitchListTile(value: state.merchantStore?.isOpen ?? false, onChanged: (v) { final s = state.merchantStore; if (s != null) context.read<SouqDerbCubit>().updateStore(s.copyWith(isOpen: v)); }, title: const Text('المتجر مفتوح'))])); } }

class MerchantOrders extends StatelessWidget { const MerchantOrders({super.key}); @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) => Scaffold(appBar: AppBar(title: const Text('الطلبات')), body: state.orders.isEmpty ? const EmptyView(icon: Icons.receipt_long, title: 'لا توجد طلبات', subtitle: 'ستظهر الطلبات الجديدة هنا') : ListView(children: state.orders.map((o) => Card(child: ListTile(title: Text('طلب ${o.number}'), subtitle: Text(orderStatusText(o.status)), trailing: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () { final next = _next(o.status); if (next != null) context.read<SouqDerbCubit>().transitionOrder(o.id, next); })))).toList()))); }
OrderStatus? _next(OrderStatus s) => switch (s) { OrderStatus.pending => OrderStatus.accepted, OrderStatus.accepted => OrderStatus.preparing, OrderStatus.preparing => OrderStatus.ready, OrderStatus.ready => OrderStatus.outForDelivery, OrderStatus.outForDelivery => OrderStatus.delivered, _ => null };

class MerchantProducts extends StatefulWidget { const MerchantProducts({super.key}); @override State<MerchantProducts> createState() => _MerchantProductsState(); }
class _MerchantProductsState extends State<MerchantProducts> {
  late Future<List<ProductData>> future;
  @override void initState() { super.initState(); future = context.read<SouqDerbCubit>().merchantProducts(); }
  void reload() => setState(() => future = context.read<SouqDerbCubit>().merchantProducts());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('المنتجات')),
    floatingActionButton: FloatingActionButton(onPressed: _edit, child: const Icon(Icons.add)),
    body: FutureBuilder<List<ProductData>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        return ListView(children: snap.data!.map((p) => Card(child: ListTile(
          title: Text(p.name),
          subtitle: Text('${p.price} ج.م • مخزون ${p.stock}'),
          trailing: Switch(value: p.available, onChanged: (v) async { await context.read<SouqDerbCubit>().saveProduct(p.copyWith(available: v)); reload(); }),
        ))).toList());
      },
    ),
  );
  Future<void> _edit() async { final name = TextEditingController(), price = TextEditingController(), stock = TextEditingController(); final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('إضافة منتج'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')), TextField(controller: price, decoration: const InputDecoration(labelText: 'السعر')), TextField(controller: stock, decoration: const InputDecoration(labelText: 'المخزون'))]), actions: [FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ'))])); if (ok == true && mounted) { final store = context.read<SouqDerbCubit>().state.merchantStore!; await context.read<SouqDerbCubit>().saveProduct(ProductData(id: 'new-${DateTime.now().microsecondsSinceEpoch}', storeId: store.id, categoryId: 'general', name: name.text, description: '', price: double.tryParse(price.text) ?? 0, stock: int.tryParse(stock.text) ?? 0)); reload(); } }
}

class MerchantStore extends StatelessWidget { const MerchantStore({super.key}); @override Widget build(BuildContext context) { final s = context.watch<SouqDerbCubit>().state.merchantStore!; return Scaffold(appBar: AppBar(title: const Text('بيانات المتجر')), body: ListView(padding: const EdgeInsets.all(16), children: [ListTile(title: Text(s.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)), subtitle: Text(s.description)), ListTile(leading: const Icon(Icons.phone), title: Text(s.phone)), ListTile(leading: const Icon(Icons.location_on), title: Text(s.address)), ListTile(leading: const Icon(Icons.delivery_dining), title: Text('${s.deliveryFee} ج.م'))])); } }
class MerchantAccount extends StatelessWidget { const MerchantAccount({super.key}); @override Widget build(BuildContext context) { final state = context.watch<SouqDerbCubit>().state; return Scaffold(appBar: AppBar(title: const Text('الحساب')), body: Padding(padding: const EdgeInsets.all(18), child: Column(children: [ListTile(title: Text(state.user!.fullName), subtitle: Text(state.user!.email)), ListTile(title: const Text('حالة الاشتراك'), trailing: Text(state.merchantStore!.subscription.name)), OutlinedButton(onPressed: () => context.read<SouqDerbCubit>().signOut(), child: const Text('تسجيل الخروج'))]))); } }

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة سوق ديرب'), actions: [IconButton(onPressed: () => context.read<SouqDerbCubit>().signOut(), icon: const Icon(Icons.logout))]),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        const SectionTitle('طلبات المتاجر'),
        if (state.stores.isEmpty) const EmptyView(icon: Icons.task_alt, title: 'لا توجد طلبات', subtitle: 'تمت مراجعة كل الطلبات')
        else ...state.stores.map((s) => Card(child: ListTile(title: Text(s.name), subtitle: Text(s.address), trailing: FilledButton(onPressed: () => context.read<SouqDerbCubit>().reviewStore(s.id, StoreApproval.approved), child: const Text('موافقة'))))),
        const SectionTitle('الإدارة'),
        const Card(child: ListTile(leading: Icon(Icons.map), title: Text('مناطق الخدمة'))),
        const Card(child: ListTile(leading: Icon(Icons.category), title: Text('أقسام المتاجر'))),
      ]),
    );
  });
}
