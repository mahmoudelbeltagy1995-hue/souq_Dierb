import 'package:flutter/material.dart';
import 'core/config/app_environment.dart';
import 'features/souq_derb/data/demo_souq_derb_repository.dart';
import 'features/souq_derb/presentation/souq_derb_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config=AppConfig(environment:AppEnvironment.demo);
  runApp(SouqDerbApp(repository:DemoSouqDerbRepository(),config:config));
}
