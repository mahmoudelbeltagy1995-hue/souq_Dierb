import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/models.dart';
import '../../../../core/config/app_environment.dart';
import '../../souq_derb/domain/souq_derb_repository.dart';
import 'cubit/souq_derb_cubit.dart';
import 'cubit/souq_derb_state.dart';
import 'screens/auth_screens.dart';
import 'screens/customer_screens.dart';
import 'screens/merchant_admin_screens.dart';
import 'widgets/common.dart';

class SouqDerbApp extends StatelessWidget {
  final SouqDerbRepository repository; final AppConfig config;
  const SouqDerbApp({super.key,required this.repository,required this.config});
  @override Widget build(BuildContext context)=>BlocProvider(create:(_)=>SouqDerbCubit(repository)..bootstrap(),child:MaterialApp(
    title:'سوق ديرب',debugShowCheckedModeBanner:false,locale:const Locale('ar','EG'),
    supportedLocales:const [Locale('ar','EG')],theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:souqGreen),scaffoldBackgroundColor:souqBg,fontFamily:'Poppins',inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder(),filled:true,fillColor:Colors.white),filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(52)))),
    home:AppGate(config:config)));
}

class AppGate extends StatelessWidget{final AppConfig config;const AppGate({super.key,required this.config});@override Widget build(BuildContext context)=>BlocConsumer<SouqDerbCubit,SouqDerbState>(listenWhen:(a,b)=>a.error!=b.error&&b.error!=null,listener:(context,state){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(state.error!),action:SnackBarAction(label:'حسنًا',onPressed:context.read<SouqDerbCubit>().clearError)));},builder:(context,state){if(state.booting)return const Scaffold(body:LoadingView(text:'نجهز سوق ديرب...'));if(state.user==null)return AuthLandingScreen(isDemo:config.isDemo);return switch(state.user!.role){AppRole.customer=>const CustomerShell(),AppRole.merchant=>const MerchantGate(),AppRole.admin=>const AdminShell(),AppRole.staff||AppRole.driver=>const Scaffold(body:EmptyView(icon:Icons.construction,title:'قريبًا',subtitle:'هذه المساحة مجهزة للمرحلة التالية'))};});}
