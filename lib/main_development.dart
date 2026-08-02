import 'package:flutter/material.dart';
import 'core/config/app_environment.dart';
import 'core/supabase/supabase_service.dart';
import 'features/souq_derb/data/supabase_souq_derb_repository.dart';
import 'features/souq_derb/presentation/souq_derb_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config=AppConfig.fromDefines(fallback:AppEnvironment.development);
  config.validate();
  await SupabaseService.initialize();
  runApp(SouqDerbApp(repository:SupabaseSouqDerbRepository(SupabaseService.instance),config:config));
}
