import 'package:flutter/material.dart';
import 'core/config/app_environment.dart';
import 'core/supabase/supabase_service.dart';
import 'features/souq_derb/data/supabase_souq_derb_repository.dart';
import 'features/souq_derb/presentation/souq_derb_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config=AppConfig.fromEnvironment();
  config.validate();
  await SupabaseService.instance.initialize(url:config.supabaseUrl,anonKey:config.supabaseAnonKey);
  runApp(SouqDerbApp(repository:SupabaseSouqDerbRepository(SupabaseService.instance),config:config,audience:AppAudience.customer));
}
