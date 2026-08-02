import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models.dart';
import '../cubit/souq_derb_cubit.dart';
import '../cubit/souq_derb_state.dart';
import '../widgets/common.dart';

class AuthLandingScreen extends StatelessWidget {
  final bool isDemo;
  const AuthLandingScreen({super.key, required this.isDemo});
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
    const SizedBox(height: 30), Image.asset('assets/logos/souq-derb-logo.png', height: 125),
    const Center(child: Text('كل ديرب في إيدك', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: souqGreen))),
    const SizedBox(height: 28), FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('تسجيل الدخول')),
    OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerRegistrationScreen())), child: const Text('إنشاء حساب عميل')),
    TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantRegistrationScreen())), icon: const Icon(Icons.storefront), label: const Text('سجّل محلك')),
    if (isDemo) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [const Text('حسابات التجربة • كلمة المرور 123456'), for (final role in ['customer', 'merchant', 'pending', 'admin']) TextButton(onPressed: () => context.read<SouqDerbCubit>().signIn('$role@souqderb.demo', '123456'), child: Text(role))]))),
  ])));
}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginState(); }
class _LoginState extends State<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('تسجيل الدخول')), body: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
    const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
    const SizedBox(height: 18), BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) => FilledButton(onPressed: state.busy ? null : () async { await context.read<SouqDerbCubit>().signIn(email.text.trim(), password.text); if (context.mounted && context.read<SouqDerbCubit>().state.user != null) Navigator.pop(context); }, child: Text(state.busy ? 'جارٍ الدخول...' : 'دخول'))),
  ])));
}

class CustomerRegistrationScreen extends StatefulWidget { const CustomerRegistrationScreen({super.key}); @override State<CustomerRegistrationScreen> createState() => _CustomerRegistrationState(); }
class _CustomerRegistrationState extends State<CustomerRegistrationScreen> {
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  String? area;
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) {
    area ??= state.areas.firstOrNull?.id;
    return Scaffold(appBar: AppBar(title: const Text('حساب عميل')), body: ListView(padding: const EdgeInsets.all(18), children: [
      _field(name, 'الاسم'), _field(phone, 'رقم الهاتف'), _field(email, 'البريد الإلكتروني'), _field(password, 'كلمة المرور', secret: true),
      DropdownButtonFormField<String>(initialValue: area, decoration: const InputDecoration(labelText: 'المنطقة'), items: state.areas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nameAr))).toList(), onChanged: (v) => area = v),
      const SizedBox(height: 16), FilledButton(onPressed: state.busy || area == null ? null : () => context.read<SouqDerbCubit>().registerCustomer(name: name.text, phone: phone.text, email: email.text, password: password.text, areaId: area!), child: const Text('إنشاء الحساب')),
    ]));
  });
}

class MerchantRegistrationScreen extends StatefulWidget { const MerchantRegistrationScreen({super.key}); @override State<MerchantRegistrationScreen> createState() => _MerchantRegistrationState(); }
class _MerchantRegistrationState extends State<MerchantRegistrationScreen> {
  final owner = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), password = TextEditingController(), store = TextEditingController(), address = TextEditingController(), whatsapp = TextEditingController(), description = TextEditingController();
  String? area, category;
  @override Widget build(BuildContext context) => BlocBuilder<SouqDerbCubit, SouqDerbState>(builder: (context, state) {
    area ??= state.areas.firstOrNull?.id; category ??= state.categories.firstOrNull?.id ?? 'restaurants';
    return Scaffold(appBar: AppBar(title: const Text('تسجيل محل')), body: ListView(padding: const EdgeInsets.all(18), children: [
      _field(owner, 'اسم صاحب النشاط'), _field(phone, 'الهاتف'), _field(email, 'البريد'), _field(password, 'كلمة المرور', secret: true), _field(store, 'اسم المتجر'), _field(address, 'عنوان المتجر'), _field(whatsapp, 'WhatsApp'), _field(description, 'وصف مختصر'),
      DropdownButtonFormField<String>(initialValue: area, decoration: const InputDecoration(labelText: 'المنطقة'), items: state.areas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nameAr))).toList(), onChanged: (v) => area = v),
      const SizedBox(height: 16), FilledButton(onPressed: state.busy || area == null ? null : () => context.read<SouqDerbCubit>().registerMerchant(MerchantRegistration(ownerName: owner.text, phone: phone.text, email: email.text, password: password.text, storeName: store.text, categoryId: category!, areaId: area!, address: address.text, whatsapp: whatsapp.text, description: description.text, serviceAreaIds: [area!])), child: const Text('إرسال طلب المراجعة')),
    ]));
  });
}

Widget _field(TextEditingController controller, String label, {bool secret = false}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controller, obscureText: secret, decoration: InputDecoration(labelText: label)));
